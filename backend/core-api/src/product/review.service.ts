import { BadRequestException, Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ReviewService {
  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async listForProduct(productId: string, page = 1, limit = 20) {
    const offset = (page - 1) * limit;
    const { data, count, error } = await this.db
      .from('product_reviews')
      .select(
        'id, rating, title, comment, created_at, customer:customers(id, full_name)',
        { count: 'exact' },
      )
      .eq('product_id', productId)
      .eq('is_visible', true)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    if (error) throw error;

    const { data: agg } = await this.db
      .from('product_reviews')
      .select('rating')
      .eq('product_id', productId)
      .eq('is_visible', true);
    const ratings = (agg || []).map((r: { rating: number }) => r.rating);
    const average = ratings.length
      ? ratings.reduce((s, r) => s + r, 0) / ratings.length
      : 0;

    return {
      data: data || [],
      total: count || 0,
      page,
      limit,
      average: Math.round(average * 10) / 10,
      totalRatings: ratings.length,
    };
  }

  async listMine(userId: string, page = 1, limit = 20) {
    // Resolve customer_id
    const { data: customer } = await this.db
      .from('customers')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
    const customerId = customer?.id;
    if (!customerId) return { data: [], total: 0, page, limit };

    const offset = (page - 1) * limit;
    const { data, count, error } = await this.db
      .from('product_reviews')
      .select(
        'id, rating, title, comment, created_at, product:products(id, name, thumbnail_url)',
        { count: 'exact' },
      )
      .eq('customer_id', customerId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  async create(
    tenantId: string,
    userId: string,
    input: {
      product_id: string;
      order_id?: string;
      rating: number;
      title?: string;
      comment?: string;
    },
  ) {
    if (!input.product_id) throw new BadRequestException('product_id required');
    if (!input.rating || input.rating < 1 || input.rating > 5) {
      throw new BadRequestException('rating must be between 1 and 5');
    }

    // Resolve customer_id
    const { data: customer } = await this.db
      .from('customers')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
    const customerId = customer?.id;

    // If order_id supplied, ensure the order belongs to this user and is completed
    if (input.order_id) {
      const { data: order } = await this.db
        .from('orders')
        .select('id, status, customer_id')
        .eq('id', input.order_id)
        .maybeSingle();
      if (!order) throw new BadRequestException('Order not found');
      if (customerId && order.customer_id && order.customer_id !== customerId) {
        throw new BadRequestException('Order does not belong to user');
      }
      if (!['completed', 'confirmed', 'processing'].includes(order.status)) {
        throw new BadRequestException(
          'Chỉ đánh giá khi đơn đã xác nhận/hoàn thành',
        );
      }
    }

    const { data, error } = await this.db
      .from('product_reviews')
      .insert({
        tenant_id: tenantId,
        product_id: input.product_id,
        order_id: input.order_id,
        customer_id: customerId,
        user_id: userId,
        rating: input.rating,
        title: input.title,
        comment: input.comment,
      })
      .select()
      .single();
    if (error) {
      if ((error as { code?: string }).code === '23505') {
        throw new BadRequestException('Bạn đã đánh giá sản phẩm này cho đơn này');
      }
      throw error;
    }
    return data;
  }

  async listForOrder(userId: string, orderId: string) {
    const { data: customer } = await this.db
      .from('customers')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();
    const customerId = customer?.id;
    if (!customerId) return [];
    const { data, error } = await this.db
      .from('product_reviews')
      .select('id, product_id, rating, title, comment, created_at')
      .eq('order_id', orderId)
      .eq('customer_id', customerId);
    if (error) throw error;
    return data || [];
  }
}
