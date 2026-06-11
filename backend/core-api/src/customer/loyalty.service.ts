import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { AdjustPointsInput } from './dto/customer.types';

@Injectable()
export class LoyaltyService {
  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async adjustPoints(tenantId: string, input: AdjustPointsInput) {
    // Insert transaction
    const { data, error } = await this.db
      .from('loyalty_transactions')
      .insert({
        tenant_id: tenantId,
        customer_id: input.customer_id,
        type: input.type,
        points: input.points,
        description: input.description,
        reference_id: input.reference_id,
      })
      .select()
      .single();

    if (error) throw error;

    // Update customer points
    const { data: customer } = await this.db
      .from('customers')
      .select('loyalty_points')
      .eq('id', input.customer_id)
      .single();

    const newPoints = (customer?.loyalty_points || 0) + input.points;

    await this.db
      .from('customers')
      .update({
        loyalty_points: Math.max(0, newPoints),
        loyalty_tier: this.calculateTier(newPoints),
      })
      .eq('id', input.customer_id);

    return data;
  }

  async getTransactions(tenantId: string, customerId: string, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const { data, count, error } = await this.db
      .from('loyalty_transactions')
      .select('*', { count: 'exact' })
      .eq('tenant_id', tenantId)
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  /** Earn points from order (e.g., 1 point per 10,000 VND) */
  async earnPointsFromOrder(
    tenantId: string,
    customerId: string,
    orderId: string,
    orderAmount: number,
  ) {
    const pointsPerUnit = 10000; // 1 point per 10,000 VND
    const points = Math.floor(orderAmount / pointsPerUnit);

    if (points <= 0) return null;

    return this.adjustPoints(tenantId, {
      customer_id: customerId,
      points,
      type: 'earn',
      description: `Tích điểm đơn hàng`,
      reference_id: orderId,
    });
  }

  /** Redeem points for discount */
  async redeemPoints(tenantId: string, customerId: string, points: number, orderId?: string) {
    const { data: customer } = await this.db
      .from('customers')
      .select('loyalty_points')
      .eq('id', customerId)
      .single();

    if (!customer || customer.loyalty_points < points) {
      throw new Error('Insufficient loyalty points');
    }

    return this.adjustPoints(tenantId, {
      customer_id: customerId,
      points: -points,
      type: 'redeem',
      description: `Đổi điểm`,
      reference_id: orderId,
    });
  }

  private calculateTier(points: number): string {
    if (points >= 10000) return 'diamond';
    if (points >= 5000) return 'gold';
    if (points >= 1000) return 'silver';
    return 'bronze';
  }
}
