import { ObjectType, Field, Float, Int } from '@nestjs/graphql';

@ObjectType()
export class DashboardStats {
  @Field(() => Float)
  today_revenue: number;

  @Field(() => Int)
  today_orders: number;

  @Field(() => Float)
  today_average_order: number;

  @Field(() => Float)
  yesterday_revenue: number;

  @Field(() => Float)
  revenue_change_percent: number;

  @Field(() => Int)
  total_customers: number;

  @Field(() => Int)
  new_customers_today: number;

  @Field(() => Int)
  low_stock_count: number;
}

@ObjectType()
export class TopProduct {
  @Field()
  product_id: string;

  @Field()
  product_name: string;

  @Field(() => Int)
  quantity_sold: number;

  @Field(() => Float)
  revenue: number;
}

@ObjectType()
export class TopCustomer {
  @Field()
  customer_id: string;

  @Field()
  customer_name: string;

  @Field(() => Int)
  order_count: number;

  @Field(() => Float)
  total_spent: number;
}

@ObjectType()
export class RevenueByPeriod {
  @Field()
  period: string;

  @Field(() => Float)
  revenue: number;

  @Field(() => Int)
  order_count: number;
}
