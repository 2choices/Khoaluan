import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import { CreateOrderInput, OrderFilterInput, OrderStatus } from './dto/order.types';

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  private cleanPaymentMethod(method: string): string {
    const cleaned = String(method || '').toLowerCase().trim();

    if (cleaned === 'chuyển khoản' || cleaned === 'bank_transfer') {
      return 'bank_transfer';
    }
    if (cleaned === 'tiền mặt' || cleaned === 'cash') {
      return 'cash';
    }
    if (cleaned === 'vietqr' || cleaned === 'payos') {
      return 'payos';
    }

    return cleaned || 'cash';
  }

  async findAll(tenantId: string, filter: OrderFilterInput = {}) {
    const page = filter.page || 1;
    const limit = filter.limit || 20;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('orders')
      .select('*, items:order_items(*), payments(*)', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (filter.status) query = query.eq('status', filter.status);
    if (filter.payment_status) {
      query = query.eq('payment_status', filter.payment_status);
    }
    if (filter.branch_id) query = query.eq('branch_id', filter.branch_id);
    if (filter.customer_id) query = query.eq('customer_id', filter.customer_id);
    if (filter.search) query = query.ilike('order_number', `%${filter.search}%`);
    if (filter.date_from) query = query.gte('created_at', filter.date_from);
    if (filter.date_to) query = query.lte('created_at', filter.date_to);

    query = query
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;

    return {
      data: data || [],
      total: count || 0,
      page,
      limit,
    };
  }

  async findById(tenantId: string, id: string) {
    const { data, error } = await this.db
      .from('orders')
      .select('*, items:order_items(*), payments(*)')
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error || !data) throw new NotFoundException('Order not found');
    return data;
  }

  async create(tenantId: string, userId: string, input: CreateOrderInput) {
    try {
      let branchId = input.branch_id;
      if (!branchId || branchId === 'default') {
        const { data: branch } = await this.db
          .from('tenant_branches')
          .select('id')
          .eq('tenant_id', tenantId)
          .limit(1)
          .maybeSingle();

        if (branch) branchId = branch.id;
      }

      let finalShiftId = input.shift_id;
      if (!finalShiftId) {
        const { data: activeShift } = await this.db
          .from('shifts')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('branch_id', branchId)
          .eq('status', 'open')
          .limit(1)
          .maybeSingle();

        if (activeShift) {
          finalShiftId = activeShift.id;
        }
      }

      const finalCreatedBy = userId || 'e2000000-0000-0000-0000-000000000001';

      let customerId = input.customer_id;
      if (!customerId && input.source === 'online' && userId) {
        const { data: existing } = await this.db
          .from('customers')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('user_id', userId)
          .maybeSingle();

        if (existing) {
          customerId = existing.id;
        } else {
          const { data: newCustomer } = await this.db
            .from('customers')
            .insert({
              tenant_id: tenantId,
              user_id: userId,
              full_name: input.shipping_name || 'Khách hàng',
              phone: input.shipping_phone,
              is_active: true,
              group_id: 'e5000000-0000-0000-0000-000000000001',
            })
            .select('id')
            .single();

          if (newCustomer) customerId = newCustomer.id;
        }
      }

      const productIds = input.items.map((i) => i.product_id);
      const { data: products } = await this.db
        .from('products')
        .select('id, name, sku, barcode, base_price, cost_price, tax_rate')
        .in('id', productIds);

      const productMap = new Map((products || []).map((p: any) => [p.id, p]));

      const orderItems = input.items.map((item) => {
        const product = productMap.get(item.product_id);
        if (!product) {
          throw new BadRequestException(`Product ${item.product_id} not found`);
        }

        const unitPrice = item.unit_price || product.base_price;
        const discount = item.discount_amount || 0;
        const finalQuantity = Math.round(Number(item.quantity || 1));
        const lineTotal = finalQuantity * unitPrice - discount;

        return {
          product_id: item.product_id,
          variant_id: item.variant_id,
          tenant_id: tenantId,
          product_name: product.name,
          sku: product.sku,
          barcode: product.barcode,
          quantity: finalQuantity,
          unit_price: unitPrice,
          cost_price: product.cost_price || 0,
          discount_amount: discount,
          discount_percent: item.discount_percent || 0,
          tax_amount: 0,
          total: lineTotal,
          note: item.note,
        };
      });

      const subtotal = orderItems.reduce((sum, i) => sum + i.total, 0);
      const discountAmount = input.discount_amount || 0;
      const shippingFee = input.shipping_fee || 0;
      const totalAmount = subtotal - discountAmount + shippingFee;

      const generatedOrderNumber = 'HD' + Date.now().toString().slice(-8);
      const finalMappedMethod = this.cleanPaymentMethod(input.payment_method || '');

      const { data: order, error: orderErr } = await this.db
        .from('orders')
        .insert({
          tenant_id: tenantId,
          branch_id: branchId,
          customer_id: customerId || 'e6000000-0000-0000-0000-000000000001',
          shift_id: finalShiftId,
          created_by: finalCreatedBy,
          order_number: input.order_number || generatedOrderNumber,
          source: input.source || 'pos',
          status: 'draft',
          subtotal,
          discount_amount: discountAmount,
          discount_percent: input.discount_percent || 0,
          shipping_fee: shippingFee,
          total_amount: totalAmount,
          payment_method: finalMappedMethod,
          note: input.note,
          is_synced: true,
        })
        .select()
        .single();

      if (orderErr) throw orderErr;

      const itemsWithOrderId = orderItems.map((item) => ({
        ...item,
        order_id: order.id,
      }));

      const { error: itemsErr } = await this.db
        .from('order_items')
        .insert(itemsWithOrderId);

      if (itemsErr) throw itemsErr;

      return this.findById(tenantId, order.id);
    } catch (err: any) {
      this.logger.error(
        `Order create error: ${err.message || JSON.stringify(err)}`,
      );
      throw new BadRequestException(
        err.message || 'Khởi tạo đơn hàng POS thất bại',
      );
    }
  }

  async getHoldOrders(tenantId: string, branchId: string) {
    const { data, error } = await this.db
      .from('orders')
      .select('*, items:order_items(*)')
      .eq('tenant_id', tenantId)
      .eq('branch_id', branchId)
      .eq('status', 'draft')
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async holdOrder(tenantId: string, userId: string, input: CreateOrderInput) {
    const saved = await this.create(tenantId, userId, input);
    await this.db.from('orders').update({ status: 'draft' }).eq('id', saved.id);
    return { ...saved, status: 'draft' };
  }

  async updateStatus(tenantId: string, orderId: string, status: OrderStatus) {
    const patch: Record<string, unknown> = {
      status,
      updated_at: new Date().toISOString(),
    };

    if (status === OrderStatus.CANCELLED) {
      patch['payment_status'] = 'refunded';
    }

    const { data, error } = await this.db
      .from('orders')
      .update(patch)
      .eq('tenant_id', tenantId)
      .eq('id', orderId)
      .select()
      .single();

    if (error || !data) {
      throw new NotFoundException('Order not found');
    }

    try {
      await this.redis.del(`orders:${tenantId}:${orderId}`);
    } catch (_) {}

    return this.findById(tenantId, orderId);
  }

  async cancelOrder(tenantId: string, orderId: string) {
    const existing = await this.findById(tenantId, orderId);

    const currentStatus = String(existing.status || '').toLowerCase();

    if (currentStatus === OrderStatus.CANCELLED) {
      return existing;
    }

    if (currentStatus === OrderStatus.COMPLETED) {
      throw new BadRequestException('Không thể hủy đơn đã hoàn thành');
    }

    const { error } = await this.db
      .from('orders')
      .update({
        status: OrderStatus.CANCELLED,
        payment_status: 'refunded',
        updated_at: new Date().toISOString(),
      })
      .eq('tenant_id', tenantId)
      .eq('id', orderId);

    if (error) {
      throw new BadRequestException(error.message || 'Hủy đơn thất bại');
    }

    try {
      await this.redis.del(`orders:${tenantId}:${orderId}`);
    } catch (_) {}

    return this.findById(tenantId, orderId);
  }

  async confirmOrder(
    tenantId: string,
    orderId: string,
    details: {
      paymentAmount: number;
      paymentMethod: string;
      userId: string;
      note?: string;
    },
  ) {
    await this.approveOrder(tenantId, orderId);
    if (details.paymentAmount > 0) {
      await this.recordPayment(
        tenantId,
        orderId,
        details.paymentAmount,
        details.paymentMethod,
        details.note,
      );
    }
    return this.findById(tenantId, orderId);
  }

  async approveOrder(tenantId: string, orderId: string) {
    try {
      const order = await this.db
        .from('orders')
        .select('*, items:order_items(*)')
        .eq('tenant_id', tenantId)
        .eq('id', orderId)
        .maybeSingle();

      if (!order.data) {
        throw new NotFoundException('Không tìm thấy đơn hàng tương ứng');
      }

      const items = order.data.items || [];

      for (const item of items) {
        const itemQty = Math.round(Number(item.quantity || 1));
        const stockRes = await this.validateProductStock(
          tenantId,
          item.product_id,
          itemQty,
        );
        if (!stockRes.available) {
          throw new BadRequestException(
            `Sản phẩm [${item.product_name}] trong kho không đủ đáp ứng.`,
          );
        }
      }

      for (const item of items) {
        const itemQty = Math.round(Number(item.quantity || 1));
        await this.createInventoryTransaction(tenantId, {
          productId: item.product_id,
          type: 'sale',
          quantity: itemQty,
          reason: 'order_confirmed',
          orderId,
          costPrice: item.cost_price || 0,
        });
      }

      const { data: updated, error } = await this.db
        .from('orders')
        .update({ status: 'confirmed' })
        .eq('tenant_id', tenantId)
        .eq('id', orderId)
        .select()
        .single();

      if (error) throw error;

      try {
        await this.redis.del(`orders:${tenantId}:${orderId}`);
      } catch (_) {}

      return updated;
    } catch (err: any) {
      this.logger.error(`Approve order failed: ${err.message}`);
      throw new BadRequestException(
        err.message || 'Xác nhận duyệt đơn hàng thất bại',
      );
    }
  }

  async recordPayment(
    tenantId: string,
    orderId: string,
    amount: number,
    method: string,
    note?: string,
  ) {
    const order = await this.findById(tenantId, orderId);
    if (!order) throw new NotFoundException('Order not found');

    const newPaidAmount = Number(order.paid_amount || 0) + amount;
    const totalAmount = Number(order.total_amount || 0);

    if (newPaidAmount > totalAmount) {
      throw new BadRequestException(
        `Số tiền thanh toán vượt quá tổng giá trị đơn hàng.`,
      );
    }

    const currentPaymentStatus =
      newPaidAmount >= totalAmount ? 'paid' : 'pending';
    const changeAmount =
      newPaidAmount > totalAmount ? newPaidAmount - totalAmount : 0;

    let finalMethod = this.cleanPaymentMethod(method);
    if (finalMethod === 'payos' || finalMethod === 'bank_transfer') {
      finalMethod = 'bank';
    }

    const { data: payment, error: payErr } = await this.db
      .from('payments')
      .insert({
        order_id: orderId,
        tenant_id: tenantId,
        method: finalMethod,
        amount,
        status: currentPaymentStatus,
        note,
      })
      .select()
      .single();

    if (payErr) {
      this.logger.error(`Chèn bảng payments thất bại: ${JSON.stringify(payErr)}`);
      throw payErr;
    }

    const { data: updated, error: updateErr } = await this.db
      .from('orders')
      .update({
        payment_status: currentPaymentStatus,
        paid_amount: newPaidAmount,
        change_amount: changeAmount,
        status: currentPaymentStatus === 'paid' ? 'completed' : order.status,
      })
      .eq('tenant_id', tenantId)
      .eq('id', orderId)
      .select()
      .single();

    if (updateErr) throw updateErr;

    try {
      await this.redis.del(`orders:${tenantId}:${orderId}`);
    } catch (_) {}

    return { order: updated, payment };
  }

  private async validateProductStock(
    tenantId: string,
    productId: string,
    requiredQty: number,
  ) {
    try {
      const { data } = await this.db
        .from('inventory')
        .select('quantity')
        .eq('tenant_id', tenantId)
        .eq('product_id', productId)
        .limit(1)
        .maybeSingle();

      if (!data) return { available: true, currentStock: 999 };
      return {
        available:
          Math.round(Number(data.quantity || 0)) >=
          Math.round(Number(requiredQty)),
        currentStock: Math.round(Number(data.quantity || 0)),
      };
    } catch (_) {
      return { available: true, currentStock: 999 };
    }
  }

  private async createInventoryTransaction(tenantId: string, data: any) {
    try {
      const targetQty = Math.round(Number(data.quantity));
      await this.db.from('stock_movements').insert({
        tenant_id: tenantId,
        warehouse_id: 'e4000000-0000-0000-0000-000000000001',
        product_id: data.productId,
        variant_id: null,
        movement_type: data.type,
        quantity: -targetQty,
        unit_cost: Number(data.costPrice || 0),
        reference_type: 'order',
        reference_id: data.orderId,
        note: `Xuất kho tự động cho đơn hàng POS`,
        created_by: 'e2000000-0000-0000-0000-000000000001',
      });

      const { data: currentInv } = await this.db
        .from('inventory')
        .select('quantity')
        .eq('product_id', data.productId)
        .maybeSingle();

      if (currentInv) {
        await this.db
          .from('inventory')
          .update({
            quantity: Math.round(Number(currentInv.quantity || 0)) - targetQty,
          })
          .eq('product_id', data.productId);
      }
    } catch (err) {
      this.logger.error(
        `Đồng bộ cập nhật kho lỗi nhẹ, bỏ qua luồng để ưu tiên thanh toán: ${JSON.stringify(err)}`,
      );
    }
  }
}