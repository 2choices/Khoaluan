import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import {
  OpenShiftInput,
  CloseShiftInput,
  ReturnOrderInput,
} from './dto/shift.types';

@Injectable()
export class ShiftService {
  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  // ==================== SHIFTS ====================

  async openShift(tenantId: string, userId: string, input: OpenShiftInput) {
    // Check no open shift for this user
    const { data: existing } = await this.db
      .from('shifts')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('user_id', userId)
      .eq('status', 'open')
      .maybeSingle();

    if (existing) {
      throw new BadRequestException('User already has an open shift');
    }

    const { data, error } = await this.db
      .from('shifts')
      .insert({
        tenant_id: tenantId,
        branch_id: input.branch_id,
        user_id: userId,
        status: 'open',
        opening_amount: input.opening_amount,
        note: input.note,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async closeShift(tenantId: string, userId: string, shiftId: string, input: CloseShiftInput) {
    // Get shift with calculated totals
    const report = await this.getShiftReport(tenantId, shiftId);

    const { data: shift } = await this.db
      .from('shifts')
      .select('opening_amount')
      .eq('id', shiftId)
      .single();

    const expectedAmount = (shift?.opening_amount || 0) + report.total_cash - report.total_refunds;
    const difference = input.closing_amount - expectedAmount;

    const { data, error } = await this.db
      .from('shifts')
      .update({
        status: 'closed',
        closing_amount: input.closing_amount,
        expected_amount: expectedAmount,
        difference,
        total_sales: report.total_sales,
        total_orders: report.total_orders,
        total_refunds: report.total_refunds,
        note: input.note,
        closed_at: new Date().toISOString(),
      })
      .eq('tenant_id', tenantId)
      .eq('id', shiftId)
      .eq('status', 'open')
      .select()
      .single();

    if (error || !data) throw new BadRequestException('Could not close shift');
    return data;
  }

  async getCurrentShift(tenantId: string, userId: string) {
    const { data } = await this.db
      .from('shifts')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('user_id', userId)
      .eq('status', 'open')
      .maybeSingle();

    return data;
  }

  async getShiftReport(tenantId: string, shiftId: string) {
    // Get orders in this shift
    const { data: orders } = await this.db
      .from('orders')
      .select('total_amount, payment_status, is_return')
      .eq('tenant_id', tenantId)
      .eq('shift_id', shiftId)
      .in('status', ['confirmed', 'completed']);

    // Get payments in this shift's orders
    const { data: payments } = await this.db
      .from('payments')
      .select('method, amount, status')
      .eq('tenant_id', tenantId)
      .in(
        'order_id',
        (orders || []).map((o: any) => o.id),
      )
      .eq('status', 'paid');

    const salesOrders = (orders || []).filter((o: any) => !o.is_return);
    const refundOrders = (orders || []).filter((o: any) => o.is_return);

    const totalCash = (payments || [])
      .filter((p: any) => p.method === 'cash')
      .reduce((sum: number, p: any) => sum + p.amount, 0);

    const totalTransfer = (payments || [])
      .filter((p: any) => p.method !== 'cash')
      .reduce((sum: number, p: any) => sum + p.amount, 0);

    return {
      total_sales: salesOrders.reduce((sum: number, o: any) => sum + o.total_amount, 0),
      total_orders: salesOrders.length,
      total_cash: totalCash,
      total_transfer: totalTransfer,
      total_refunds: refundOrders.reduce((sum: number, o: any) => sum + Math.abs(o.total_amount), 0),
      expected_cash: totalCash,
    };
  }

  async getShiftHistory(tenantId: string, branchId?: string, page = 1, limit = 20) {
    const offset = (page - 1) * limit;
    let query = this.db
      .from('shifts')
      .select('*', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (branchId) query = query.eq('branch_id', branchId);

    query = query.order('opened_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  // ==================== RETURNS ====================

  async createReturn(tenantId: string, userId: string, input: ReturnOrderInput) {
    // Get original order
    const { data: originalOrder } = await this.db
      .from('orders')
      .select('*, items:order_items(*)')
      .eq('tenant_id', tenantId)
      .eq('id', input.original_order_id)
      .single();

    if (!originalOrder) throw new NotFoundException('Original order not found');

    // Build return items from original order items
    const returnItems = input.items.map((ri) => {
      const originalItem = (originalOrder.items || []).find(
        (oi: any) => oi.id === ri.order_item_id,
      );
      if (!originalItem) throw new BadRequestException(`Order item ${ri.order_item_id} not found`);
      if (ri.quantity > originalItem.quantity) {
        throw new BadRequestException(`Return quantity exceeds original for item ${ri.order_item_id}`);
      }

      return {
        product_id: originalItem.product_id,
        variant_id: originalItem.variant_id,
        tenant_id: tenantId,
        product_name: originalItem.product_name,
        variant_name: originalItem.variant_name,
        sku: originalItem.sku,
        quantity: -ri.quantity,
        unit_price: originalItem.unit_price,
        cost_price: originalItem.cost_price,
        discount_amount: 0,
        tax_amount: 0,
        total: -(ri.quantity * originalItem.unit_price),
        note: ri.reason,
      };
    });

    const totalRefund = Math.abs(returnItems.reduce((sum, i) => sum + i.total, 0));

    // Create return order
    const { data: returnOrder, error } = await this.db
      .from('orders')
      .insert({
        tenant_id: tenantId,
        branch_id: input.branch_id,
        customer_id: originalOrder.customer_id,
        shift_id: input.shift_id,
        created_by: userId,
        order_number: '',
        source: 'pos',
        status: 'completed',
        subtotal: -totalRefund,
        total_amount: -totalRefund,
        payment_status: 'refunded',
        is_return: true,
        original_order_id: input.original_order_id,
        note: input.note || `Đổi/trả từ đơn ${originalOrder.order_number}`,
      })
      .select()
      .single();

    if (error) throw error;

    // Insert return items
    const itemsWithOrder = returnItems.map((item) => ({
      ...item,
      order_id: returnOrder.id,
    }));

    await this.db.from('order_items').insert(itemsWithOrder);

    return returnOrder;
  }
}
