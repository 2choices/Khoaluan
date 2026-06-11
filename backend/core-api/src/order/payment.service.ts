import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    private supabase: SupabaseService,
    private config: ConfigService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  private mapPaymentMethod(method: string): string {
    const cleaned = String(method).toLowerCase().trim();
    if (cleaned === 'bank_transfer' || cleaned === 'bank') return 'bank';
    if (cleaned === 'card' || cleaned === 'credit_card') return 'credit_card';
    if (cleaned === 'cash') return 'cash';
    if (cleaned === 'momo') return 'momo';
    if (cleaned === 'vnpay') return 'vnpay';
    if (cleaned === 'payos') return 'bank';
    return 'unknown';
  }

  async createPayment(tenantId: string, input: any) {
    const { data: order } = await this.db
      .from('orders')
      .select('total_amount, paid_amount, payment_status, status')
      .eq('tenant_id', tenantId)
      .eq('id', input.order_id)
      .single();

    if (!order) throw new BadRequestException('Order not found');

    const mappedMethod = this.mapPaymentMethod(input.method);
    const isPaid = mappedMethod === 'cash' || mappedMethod === 'bank';

    const { data: payment, error } = await this.db
      .from('payments')
      .insert({
        tenant_id: tenantId,
        order_id: input.order_id,
        method: mappedMethod,
        amount: input.amount,
        status: isPaid ? 'paid' : 'pending',
        reference_code: input.reference_code,
        paid_at: isPaid ? new Date().toISOString() : null,
      })
      .select()
      .single();

    if (error) throw error;

    const newPaidAmount =
        Number(order.paid_amount || 0) + (isPaid ? Number(input.amount) : 0);
    const changeAmount =
        Math.max(0, newPaidAmount - Number(order.total_amount));
    const paymentStatus =
        newPaidAmount >= Number(order.total_amount) ? 'paid' : 'pending';

    await this.db
      .from('orders')
      .update({
        paid_amount: newPaidAmount,
        change_amount: changeAmount,
        payment_status: paymentStatus,
        payment_method: mappedMethod,
        status: paymentStatus === 'paid' ? 'completed' : order.status,
        updated_at: new Date().toISOString(),
      })
      .eq('id', input.order_id);

    return payment;
  }

  async createPayOSPayment(tenantId: string, orderId: string) {
  const { data: order } = await this.db
    .from('orders')
    .select('id, order_number, total_amount, paid_amount')
    .eq('tenant_id', tenantId)
    .eq('id', orderId)
    .single();

  if (!order) throw new BadRequestException('Order not found');

  const remainingAmount =
      Number(order.total_amount) - Number(order.paid_amount || 0);

  if (remainingAmount <= 0) {
    throw new BadRequestException('Order already fully paid');
  }

  const clientId = this.config.get<string>('PAYOS_CLIENT_ID');
  const apiKey = this.config.get<string>('PAYOS_API_KEY');
  const checksumKey = this.config.get<string>('PAYOS_CHECKSUM_KEY');
  const baseUrl =
      this.config.get<string>('CORS_ORIGINS') ?? 'http://localhost:3000';

  if (!clientId || !apiKey || !checksumKey) {
    throw new BadRequestException('PayOS not configured');
  }

  const orderCode = Date.now();

  await this.db.from('payments').insert({
    tenant_id: tenantId,
    order_id: orderId,
    method: 'bank',
    amount: remainingAmount,
    status: 'pending',
    reference_code: String(orderCode),
  });

  const body = {
    orderCode,
    amount: Math.round(remainingAmount),
    description: `Thanh toan ${order.order_number}`,
    cancelUrl: `${baseUrl}/payment/cancel`,
    returnUrl: `${baseUrl}/payment/success`,
  };

  const sortedData =
      `amount=${body.amount}` +
      `&cancelUrl=${body.cancelUrl}` +
      `&description=${body.description}` +
      `&orderCode=${body.orderCode}` +
      `&returnUrl=${body.returnUrl}`;

  const signature = crypto
      .createHmac('sha256', checksumKey)
      .update(sortedData)
      .digest('hex');

  const response = await fetch(
    'https://api-merchant.payos.vn/v2/payment-requests',
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-client-id': clientId,
        'x-api-key': apiKey,
      },
      body: JSON.stringify({ ...body, signature }),
    },
  );

  const result = await response.json();

  if (result.code !== '00') {
    throw new BadRequestException(`PayOS error: ${result.desc}`);
  }

  return {
    checkoutUrl: result.data.checkoutUrl,
    qrCode: result.data.qrCode,
    orderCode,
  };
}

  async confirmPayOSOrder(tenantId: string, orderId: string) {
    const { data: order, error: orderErr } = await this.db
      .from('orders')
      .select('id, total_amount, paid_amount, payment_status, status, payment_method')
      .eq('tenant_id', tenantId)
      .eq('id', orderId)
      .single();

    if (orderErr || !order) {
      throw new BadRequestException('Không tìm thấy đơn hàng');
    }

    if (String(order.payment_status) === 'paid') {
      return {
        success: true,
        alreadyPaid: true,
        order,
      };
    }

    const remainingAmount =
        Math.max(0, Number(order.total_amount || 0) - Number(order.paid_amount || 0));

    if (remainingAmount <= 0) {
      const { data: updatedOrder } = await this.db
        .from('orders')
        .update({
          payment_status: 'paid',
          status: 'completed',
          updated_at: new Date().toISOString(),
        })
        .eq('id', orderId)
        .select()
        .single();

      return {
        success: true,
        alreadyPaid: true,
        order: updatedOrder ?? order,
      };
    }

    const { data: existingPending } = await this.db
      .from('payments')
      .select('id, amount, reference_code')
      .eq('tenant_id', tenantId)
      .eq('order_id', orderId)
      .eq('method', 'bank')
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (existingPending?.id != null) {
      const { error: payErr } = await this.db
        .from('payments')
        .update({
          status: 'paid',
          paid_at: new Date().toISOString(),
        })
        .eq('id', existingPending.id);

      if (payErr) throw payErr;
    } else {
      const { error: insertErr } = await this.db
        .from('payments')
        .insert({
          tenant_id: tenantId,
          order_id: orderId,
          method: 'bank',
          amount: remainingAmount,
          status: 'paid',
          paid_at: new Date().toISOString(),
          reference_code: `manual-${Date.now()}`,
        });

      if (insertErr) throw insertErr;
    }

    const newPaidAmount = Number(order.paid_amount || 0) + remainingAmount;

    const { data: updatedOrder, error: updateErr } = await this.db
      .from('orders')
      .update({
        paid_amount: newPaidAmount,
        change_amount: Math.max(0, newPaidAmount - Number(order.total_amount || 0)),
        payment_status: 'paid',
        payment_method: 'bank',
        status: 'completed',
        updated_at: new Date().toISOString(),
      })
      .eq('tenant_id', tenantId)
      .eq('id', orderId)
      .select()
      .single();

    if (updateErr) throw updateErr;

    return {
      success: true,
      alreadyPaid: false,
      order: updatedOrder,
    };
  }

  async handlePayOSWebhook(payload: any, signature: string) {
    const checksumKey = this.config.get<string>('PAYOS_CHECKSUM_KEY', '');

    const webhookData = payload?.data ?? {};
    const rawOrderCode = webhookData.orderCode ?? payload?.orderCode;
    const orderCode = String(rawOrderCode ?? '');

    await this.db.from('payos_webhook_logs').insert({
      order_code: orderCode,
      raw_payload: payload,
      signature,
      is_verified: false,
    });

    const sortedData = Object.keys(webhookData)
      .sort()
      .map((k) => `${k}=${webhookData[k]}`)
      .join('&');

    const expectedSig = crypto
      .createHmac('sha256', checksumKey)
      .update(sortedData)
      .digest('hex');

    if (expectedSig !== signature) {
      throw new BadRequestException('Invalid webhook signature');
    }

    await this.db
      .from('payos_webhook_logs')
      .update({ is_verified: true })
      .eq('order_code', orderCode);

    const isPaid =
  payload?.code === '00' ||
  payload?.success === true ||
  webhookData?.code === '00' ||
  String(webhookData?.status ?? '').toUpperCase() === 'PAID';

    if (!isPaid) {
      return {
        success: true,
        message: 'Webhook received but payment not marked paid.',
      };
    }

    let payment: any = null;

    const paymentRes = await this.db
      .from('payments')
      .select('id, order_id, amount, tenant_id, method')
      .eq('reference_code', orderCode)
      .limit(1)
      .maybeSingle();

    if (paymentRes.data) {
      payment = paymentRes.data;
    }

    if (!payment) {
      const orderRes = await this.db
        .from('orders')
        .select('id, tenant_id, total_amount, paid_amount, order_number, status')
        .eq('order_number', orderCode)
        .limit(1)
        .maybeSingle();

      if (orderRes.data) {
        const order = orderRes.data;

        const insertedPayment = await this.db
          .from('payments')
          .insert({
            order_id: order.id,
            tenant_id: order.tenant_id,
            method: 'bank',
            amount: Number(order.total_amount || 0),
            status: 'paid',
            paid_at: new Date().toISOString(),
            reference_code: orderCode,
            metadata: payload,
          })
          .select('id, order_id, amount, tenant_id, method')
          .single();

        if (insertedPayment.error) {
          throw insertedPayment.error;
        }

        payment = insertedPayment.data;
      }
    }

    if (!payment) {
      await this.db
        .from('payos_webhook_logs')
        .update({ is_processed: false })
        .eq('order_code', orderCode);

      return {
        success: false,
        message: `No payment/order matched for orderCode ${orderCode}`,
      };
    }

    await this.db
      .from('payments')
      .update({
        status: 'paid',
        paid_at: new Date().toISOString(),
        metadata: payload,
      })
      .eq('id', payment.id);

    const { data: order } = await this.db
      .from('orders')
      .select('id, total_amount, paid_amount, status')
      .eq('id', payment.order_id)
      .single();

    if (order) {
      const newPaid = Math.max(
        Number(order.paid_amount || 0),
        Number(payment.amount || 0),
      );

      const fullyPaid = newPaid >= Number(order.total_amount || 0);

      await this.db
        .from('orders')
        .update({
          paid_amount: newPaid,
          payment_status: fullyPaid ? 'paid' : 'pending',
          status: fullyPaid ? 'completed' : order.status,
          payment_method: 'bank',
          updated_at: new Date().toISOString(),
        })
        .eq('id', payment.order_id);
    }

    await this.db
      .from('payos_webhook_logs')
      .update({ is_processed: true })
      .eq('order_code', orderCode);

    return { success: true };
  }
}