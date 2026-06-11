import { ObjectType, Field, ID, Float, Int, InputType, registerEnumType } from '@nestjs/graphql';
import { GraphQLJSON } from 'graphql-type-json';

// ---- Enums ----

export enum StockMovementType {
  IN = 'in',
  OUT = 'out',
  TRANSFER = 'transfer',
  ADJUSTMENT = 'adjustment',
  RETURN = 'return',
}

registerEnumType(StockMovementType, { name: 'StockMovementType' });

// ---- Inventory ----

@ObjectType()
export class Inventory {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field(() => Int)
  quantity: number;

  @Field(() => Int)
  reserved_quantity: number;

  @Field(() => Int)
  min_quantity: number;

  @Field(() => Int)
  max_quantity: number;

  @Field()
  updated_at: Date;
}

@ObjectType()
export class Warehouse {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field({ nullable: true })
  branch_id?: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  address?: string;

  @Field({ nullable: true })
  phone?: string;

  @Field()
  is_active: boolean;

  @Field()
  is_default: boolean;

  @Field()
  created_at: Date;
}

@ObjectType()
export class StockMovement {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field(() => StockMovementType)
  movement_type: StockMovementType;

  @Field(() => Int)
  quantity: number;

  @Field({ nullable: true })
  reference_type?: string;

  @Field({ nullable: true })
  reference_id?: string;

  @Field({ nullable: true })
  note?: string;

  @Field({ nullable: true })
  created_by?: string;

  @Field()
  created_at: Date;
}

@ObjectType()
export class StockBatch {
  @Field(() => ID)
  id: string;

  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field()
  batch_number: string;

  @Field(() => Int)
  quantity: number;

  @Field({ nullable: true })
  manufacturing_date?: Date;

  @Field({ nullable: true })
  expiry_date?: Date;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field()
  created_at: Date;
}

@ObjectType()
export class LowStockAlert {
  @Field()
  product_id: string;

  @Field()
  product_name: string;

  @Field()
  warehouse_name: string;

  @Field(() => Int)
  current_quantity: number;

  @Field(() => Int)
  min_quantity: number;
}

// ---- Inputs ----

@InputType()
export class CreateWarehouseInput {
  @Field()
  name: string;

  @Field({ nullable: true })
  branch_id?: string;

  @Field({ nullable: true })
  address?: string;

  @Field({ nullable: true })
  phone?: string;

  @Field({ nullable: true, defaultValue: true })
  is_active?: boolean;

  @Field({ nullable: true, defaultValue: false })
  is_default?: boolean;
}

@InputType()
export class CreateStockMovementInput {
  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field(() => StockMovementType)
  movement_type: StockMovementType;

  @Field(() => Int)
  quantity: number;

  @Field({ nullable: true })
  reference_type?: string;

  @Field({ nullable: true })
  reference_id?: string;

  @Field({ nullable: true })
  note?: string;
}

@InputType()
export class StocktakeInput {
  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field(() => Int)
  actual_quantity: number;

  @Field({ nullable: true })
  note?: string;
}

@InputType()
export class CreateBatchInput {
  @Field()
  product_id: string;

  @Field({ nullable: true })
  variant_id?: string;

  @Field()
  warehouse_id: string;

  @Field()
  batch_number: string;

  @Field(() => Int)
  quantity: number;

  @Field({ nullable: true })
  manufacturing_date?: Date;

  @Field({ nullable: true })
  expiry_date?: Date;

  @Field(() => Float, { nullable: true })
  cost_price?: number;
}

@InputType()
export class InventoryFilterInput {
  @Field({ nullable: true })
  warehouse_id?: string;

  @Field({ nullable: true })
  product_id?: string;

  @Field({ nullable: true })
  low_stock_only?: boolean;

  @Field(() => Int, { nullable: true, defaultValue: 1 })
  page?: number;

  @Field(() => Int, { nullable: true, defaultValue: 50 })
  limit?: number;
}
