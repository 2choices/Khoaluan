import { ObjectType, Field, ID, Float, Int, InputType } from '@nestjs/graphql';

@ObjectType()
export class CustomerGroup {
  @Field(() => ID)
  id: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => Float, { nullable: true })
  discount_percent?: number;

  @Field(() => Int, { nullable: true })
  min_points?: number;

  @Field()
  is_active: boolean;
}

@ObjectType()
export class Customer {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field({ nullable: true })
  group_id?: string;

  @Field()
  full_name: string;

  @Field({ nullable: true })
  phone?: string;

  @Field({ nullable: true })
  email?: string;

  @Field({ nullable: true })
  address?: string;

  @Field({ nullable: true })
  date_of_birth?: Date;

  @Field({ nullable: true })
  gender?: string;

  @Field(() => Int)
  loyalty_points: number;

  @Field({ nullable: true })
  loyalty_tier?: string;

  @Field(() => Float)
  total_spent: number;

  @Field(() => Int)
  total_orders: number;

  @Field({ nullable: true })
  last_order_at?: Date;

  @Field({ nullable: true })
  note?: string;

  @Field()
  is_active: boolean;

  @Field()
  created_at: Date;

  @Field(() => CustomerGroup, { nullable: true })
  group?: CustomerGroup;
}

@ObjectType()
export class LoyaltyTransaction {
  @Field(() => ID)
  id: string;

  @Field()
  customer_id: string;

  @Field()
  type: string;

  @Field(() => Int)
  points: number;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  reference_id?: string;

  @Field()
  created_at: Date;
}

@ObjectType()
export class PaginatedCustomers {
  @Field(() => [Customer])
  data: Customer[];

  @Field(() => Int)
  total: number;

  @Field(() => Int)
  page: number;

  @Field(() => Int)
  limit: number;
}

// ---- Inputs ----

@InputType()
export class CreateCustomerInput {
  @Field()
  full_name: string;

  @Field({ nullable: true })
  phone?: string;

  @Field({ nullable: true })
  email?: string;

  @Field({ nullable: true })
  address?: string;

  @Field({ nullable: true })
  date_of_birth?: Date;

  @Field({ nullable: true })
  gender?: string;

  @Field({ nullable: true })
  group_id?: string;

  @Field({ nullable: true })
  note?: string;
}

@InputType()
export class UpdateCustomerInput {
  @Field({ nullable: true })
  full_name?: string;

  @Field({ nullable: true })
  phone?: string;

  @Field({ nullable: true })
  email?: string;

  @Field({ nullable: true })
  address?: string;

  @Field({ nullable: true })
  date_of_birth?: Date;

  @Field({ nullable: true })
  gender?: string;

  @Field({ nullable: true })
  group_id?: string;

  @Field({ nullable: true })
  note?: string;

  @Field({ nullable: true })
  is_active?: boolean;
}

@InputType()
export class CustomerFilterInput {
  @Field({ nullable: true })
  search?: string;

  @Field({ nullable: true })
  group_id?: string;

  @Field({ nullable: true })
  is_active?: boolean;

  @Field({ nullable: true })
  loyalty_tier?: string;

  @Field(() => Int, { nullable: true, defaultValue: 1 })
  page?: number;

  @Field(() => Int, { nullable: true, defaultValue: 20 })
  limit?: number;
}

@InputType()
export class CreateCustomerGroupInput {
  @Field()
  name: string;

  @Field({ nullable: true })
  description?: string;

  @Field(() => Float, { nullable: true })
  discount_percent?: number;

  @Field(() => Int, { nullable: true })
  min_points?: number;
}

@InputType()
export class AdjustPointsInput {
  @Field()
  customer_id: string;

  @Field(() => Int)
  points: number;

  @Field()
  type: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  reference_id?: string;
}
