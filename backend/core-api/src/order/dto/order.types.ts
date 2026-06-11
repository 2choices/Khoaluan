import { ObjectType, Field, ID, Float, Int, InputType, registerEnumType } from '@nestjs/graphql';
import { GraphQLJSON } from 'graphql-type-json';

export enum OrderStatus {
  DRAFT = 'draft',
  CONFIRMED = 'confirmed',
  PROCESSING = 'processing',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  RETURNED = 'returned',
}

export enum PaymentStatus {
  PENDING = 'pending',
  PARTIAL = 'partial',
  PAID = 'paid',
  REFUNDED = 'refunded',
}

export enum PaymentMethod {
  CASH = 'cash',
  BANK = 'bank',
  BANK_TRANSFER = 'bank_transfer',
  CREDIT_CARD = 'credit_card',
  CREDIT = 'credit',
  PAYOS = 'payos',
  VIETQR = 'vietqr',
  MOMO = 'momo',
  VNPAY = 'vnpay',
  ZALO_PAY = 'zalo_pay',
  UNKNOWN = 'unknown'
}

export enum OrderSource {
  POS = 'pos',
  ONLINE = 'online',
  KIOSK = 'kiosk',
}

registerEnumType(OrderStatus, { name: 'OrderStatus' });
registerEnumType(PaymentStatus, { name: 'PaymentStatus' });
registerEnumType(PaymentMethod, { name: 'PaymentMethod' });
registerEnumType(OrderSource, { name: 'OrderSource' });

@ObjectType()
export class OrderItem {
  @Field(() => ID) id: string;
  @Field() order_id: string;
  @Field() product_id: string;
  @Field({ nullable: true }) variant_id?: string;
  @Field() product_name: string;
  @Field({ nullable: true }) variant_name?: string;
  @Field(() => Float) quantity: number;
  @Field(() => Float) unit_price: number;
  @Field(() => Float) discount_amount: number;
  @Field(() => Float) tax_amount: number;
  @Field(() => Float) total: number;
  @Field({ nullable: true }) note?: string;
}

@ObjectType()
export class Payment {
  @Field(() => ID) id: string;
  @Field() order_id: string;
  @Field(() => PaymentMethod) method: PaymentMethod;
  @Field(() => Float) amount: number;
  @Field(() => PaymentStatus) status: PaymentStatus;
  @Field({ nullable: true }) reference_code?: string;
  @Field(() => GraphQLJSON, { nullable: true }) metadata?: Record<string, unknown>;
  @Field({ nullable: true }) paid_at?: Date;
  @Field() created_at: Date;
}

@ObjectType()
export class Order {
  @Field(() => ID) id: string;
  @Field() tenant_id: string;
  @Field() branch_id: string;
  @Field({ nullable: true }) customer_id?: string;
  @Field({ nullable: true }) shift_id?: string;
  @Field() order_number: string;
  @Field(() => OrderSource) source: OrderSource;
  @Field(() => OrderStatus) status: OrderStatus;
  @Field(() => Float) subtotal: number;
  @Field(() => Float) discount_amount: number;
  @Field(() => Float) tax_amount: number;
  @Field(() => Float) shipping_fee: number;
  @Field(() => Float) total_amount: number;
  @Field(() => Float) paid_amount: number;
  @Field(() => Float) change_amount: number;
  @Field(() => PaymentStatus) payment_status: PaymentStatus;
  @Field(() => PaymentMethod, { nullable: true }) payment_method?: PaymentMethod;
  @Field({ nullable: true }) note?: string;
  @Field() is_synced: boolean;
  @Field() is_return: boolean;
  @Field() created_at: Date;
  @Field() updated_at: Date;
  @Field(() => [OrderItem], { nullable: true }) items?: OrderItem[];
  @Field(() => [Payment], { nullable: true }) payments?: Payment[];
}

@InputType()
export class CreateOrderItemInput {
  @Field() product_id: string;
  @Field({ nullable: true }) variant_id?: string;
  @Field(() => Float) quantity: number;
  @Field(() => Float) unit_price: number;
  @Field(() => Float, { nullable: true, defaultValue: 0 }) discount_amount?: number;
  @Field(() => Float, { nullable: true, defaultValue: 0 }) discount_percent?: number;
  @Field({ nullable: true }) note?: string;
}

@InputType()
export class CreateOrderInput {
  @Field({ nullable: true }) branch_id?: string;
  @Field({ nullable: true }) customer_id?: string;
  @Field({ nullable: true }) shift_id?: string;
  @Field(() => OrderSource, { nullable: true, defaultValue: OrderSource.POS }) source?: OrderSource;
  @Field(() => PaymentMethod, { nullable: true }) payment_method?: PaymentMethod;
  @Field(() => [CreateOrderItemInput]) items: CreateOrderItemInput[];
  @Field(() => Float, { nullable: true, defaultValue: 0 }) discount_amount?: number;
  @Field(() => Float, { nullable: true, defaultValue: 0 }) discount_percent?: number;
  @Field(() => Float, { nullable: true, defaultValue: 0 }) shipping_fee?: number;
  @Field({ nullable: true }) voucher_code?: string;
  @Field({ nullable: true }) voucher_id?: string;
  @Field({ nullable: true }) note?: string;
  @Field({ nullable: true }) internal_note?: string;
  @Field({ nullable: true }) shipping_address?: string;
  @Field({ nullable: true }) shipping_phone?: string;
  @Field({ nullable: true }) shipping_name?: string;
  @Field({ nullable: true }) offline_id?: string;
  @Field({ nullable: true }) order_number?: string;
}

@InputType()
export class CreatePaymentInput {
  @Field() order_id: string;
  @Field(() => PaymentMethod) method: PaymentMethod;
  @Field(() => Float) amount: number;
  @Field({ nullable: true }) reference_code?: string;
}

@InputType()
export class OrderFilterInput {
  @Field(() => OrderStatus, { nullable: true }) status?: OrderStatus;
  @Field(() => PaymentStatus, { nullable: true }) payment_status?: PaymentStatus;
  @Field({ nullable: true }) branch_id?: string;
  @Field({ nullable: true }) customer_id?: string;
  @Field({ nullable: true }) search?: string;
  @Field({ nullable: true }) date_from?: Date;
  @Field({ nullable: true }) date_to?: Date;
  @Field(() => Int, { nullable: true, defaultValue: 1 }) page?: number;
  @Field(() => Int, { nullable: true, defaultValue: 20 }) limit?: number;
}