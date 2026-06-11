import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class VoucherService {
  private readonly logger = new Logger(VoucherService.name);

  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Create voucher/promotion */
  async create(tenantId: string, params: {
    code: string;
    name: string;
    description?: string;
    type?: 'percentage' | 'fixed_amount' | 'free_shipping';
    discount_type?: 'percentage' | 'fixed_amount' | 'free_shipping';
    value?: number;
    discount_value?: number;
    min_order_amount?: number;
    max_discount?: number;
    usage_limit?: number;
    per_customer_limit?: number;
    per_user_limit?: number;
    start_date?: string;
    end_date?: string;
    starts_at?: string;
    ends_at?: string;
    product_ids?: string[];
    category_ids?: string[];
  }) {
    const type = params.type || params.discount_type || 'percentage';
    const value = params.value ?? params.discount_value ?? 0;
    const startDate = params.start_date || params.starts_at || new Date().toISOString();
    const endDate = params.end_date || params.ends_at;

    const { data, error } = await this.db
      .from('vouchers')
      .insert({
        tenant_id: tenantId,
        code: params.code.toUpperCase(),
        name: params.name,
        description: params.description,
        type,
        value,
        min_order_amount: params.min_order_amount || 0,
        max_discount: params.max_discount,
        usage_limit: params.usage_limit,
        per_customer_limit: params.per_customer_limit || params.per_user_limit || 1,
        usage_count: 0,
        start_date: startDate,
        end_date: endDate,
        applicable_products: params.product_ids || [],
        applicable_categories: params.category_ids || [],
        status: 'active',
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** List vouchers */
  async findAll(tenantId: string, page = 1, limit = 20, isActive?: boolean) {
    const offset = (page - 1) * limit;
    let query = this.db
      .from('vouchers')
      .select('*', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (isActive !== undefined) {
      query = query.eq('status', isActive ? 'active' : 'disabled');
    }

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  /** Get voucher by ID */
  async findById(tenantId: string, id: string) {
    const { data, error } = await this.db
      .from('vouchers')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error) throw error;
    return data;
  }

  /** Validate and apply voucher by code */
  async validateCode(tenantId: string, code: string, orderAmount: number, userId?: string) {
    const { data: voucher, error } = await this.db
      .from('vouchers')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('code', code.toUpperCase())
      .eq('status', 'active')
      .single();

    if (error || !voucher) {
      throw new BadRequestException('Mã giảm giá không hợp lệ');
    }

    const now = new Date();
    if (voucher.start_date && new Date(voucher.start_date) > now) {
      throw new BadRequestException('Mã giảm giá chưa có hiệu lực');
    }
    if (voucher.end_date && new Date(voucher.end_date) < now) {
      throw new BadRequestException('Mã giảm giá đã hết hạn');
    }
    if (voucher.usage_limit && voucher.usage_count >= voucher.usage_limit) {
      throw new BadRequestException('Mã giảm giá đã hết lượt sử dụng');
    }
    if (voucher.min_order_amount && orderAmount < voucher.min_order_amount) {
      throw new BadRequestException(
        `Đơn hàng tối thiểu ${voucher.min_order_amount.toLocaleString()}đ`,
      );
    }

    // Check per-user limit
    if (userId && voucher.per_customer_limit) {
      const { count } = await this.db
        .from('voucher_usages')
        .select('*', { count: 'exact', head: true })
        .eq('voucher_id', voucher.id)
        .eq('customer_id', userId);

      if ((count || 0) >= voucher.per_customer_limit) {
        throw new BadRequestException('Bạn đã sử dụng hết lượt cho mã này');
      }
    }

    // Calculate discount
    let discount = 0;
    if (voucher.type === 'percentage') {
      discount = Math.round(orderAmount * voucher.value / 100);
      if (voucher.max_discount) {
        discount = Math.min(discount, voucher.max_discount);
      }
    } else if (voucher.type === 'fixed_amount') {
      discount = voucher.value;
    }

    return { voucher, discount };
  }

  /** Record voucher usage */
  async recordUsage(voucherId: string, orderId: string, customerId: string, discount: number) {
    await this.db.from('voucher_usages').insert({
      voucher_id: voucherId,
      order_id: orderId,
      customer_id: customerId,
      discount_amount: discount,
    });
  }

  /** Update voucher */
  async update(tenantId: string, id: string, params: Record<string, any>) {
    const { data, error } = await this.db
      .from('vouchers')
      .update(params)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** Toggle voucher active status */
  async toggleActive(tenantId: string, id: string) {
    const voucher = await this.findById(tenantId, id);
    return this.update(tenantId, id, {
      status: voucher.status === 'active' ? 'disabled' : 'active',
    });
  }

  /** Delete voucher */
  async delete(tenantId: string, id: string) {
    const { error } = await this.db
      .from('vouchers')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    return true;
  }
}
