import { ObjectType, Field, ID, Float, Int, InputType, registerEnumType } from '@nestjs/graphql';

export enum ShiftStatus {
  OPEN = 'open',
  CLOSED = 'closed',
}

registerEnumType(ShiftStatus, { name: 'ShiftStatus' });

@ObjectType()
export class Shift {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field()
  branch_id: string;

  @Field()
  user_id: string;

  @Field(() => ShiftStatus)
  status: ShiftStatus;

  @Field(() => Float)
  opening_amount: number;

  @Field(() => Float, { nullable: true })
  closing_amount?: number;

  @Field(() => Float, { nullable: true })
  expected_amount?: number;

  @Field(() => Float, { nullable: true })
  difference?: number;

  @Field(() => Float)
  total_sales: number;

  @Field(() => Int)
  total_orders: number;

  @Field(() => Float)
  total_refunds: number;

  @Field({ nullable: true })
  note?: string;

  @Field()
  opened_at: Date;

  @Field({ nullable: true })
  closed_at?: Date;
}

@ObjectType()
export class ShiftReport {
  @Field(() => Float)
  total_sales: number;

  @Field(() => Int)
  total_orders: number;

  @Field(() => Float)
  total_cash: number;

  @Field(() => Float)
  total_transfer: number;

  @Field(() => Float)
  total_refunds: number;

  @Field(() => Float)
  expected_cash: number;
}

@InputType()
export class OpenShiftInput {
  @Field()
  branch_id: string;

  @Field(() => Float, { defaultValue: 0 })
  opening_amount: number;

  @Field({ nullable: true })
  note?: string;
}

@InputType()
export class CloseShiftInput {
  @Field(() => Float)
  closing_amount: number;

  @Field({ nullable: true })
  note?: string;
}

@InputType()
export class ReturnItemInput {
  @Field()
  order_item_id: string;

  @Field(() => Float)
  quantity: number;

  @Field({ nullable: true })
  reason?: string;
}

@InputType()
export class ReturnOrderInput {
  @Field()
  original_order_id: string;

  @Field()
  branch_id: string;

  @Field({ nullable: true })
  shift_id?: string;

  @Field(() => [ReturnItemInput])
  items: ReturnItemInput[];

  @Field({ nullable: true })
  note?: string;
}
