import { ObjectType, Field, ID, Float, Int, InputType } from '@nestjs/graphql';
import { GraphQLJSON } from 'graphql-type-json';

// ---- Category ----

@ObjectType()
export class Category {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field({ nullable: true })
  parent_id?: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  image_url?: string;

  @Field(() => Int)
  sort_order: number;

  @Field()
  is_active: boolean;

  @Field()
  created_at: Date;

  @Field()
  updated_at: Date;

  @Field(() => [Category], { nullable: true })
  children?: Category[];
}

// ---- Product Variant ----

@ObjectType()
export class ProductVariant {
  @Field(() => ID)
  id: string;

  @Field()
  product_id: string;

  @Field()
  tenant_id: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field({ nullable: true })
  image_url?: string;

  @Field()
  is_active: boolean;

  @Field(() => Int)
  sort_order: number;

  @Field()
  created_at: Date;

  @Field()
  updated_at: Date;
}

// ---- Product Image ----

@ObjectType()
export class ProductImage {
  @Field(() => ID)
  id: string;

  @Field()
  product_id: string;

  @Field()
  url: string;

  @Field({ nullable: true })
  thumbnail_url?: string;

  @Field({ nullable: true })
  small_url?: string;

  @Field({ nullable: true })
  alt_text?: string;

  @Field(() => Int)
  sort_order: number;

  @Field()
  is_primary: boolean;

  @Field()
  created_at: Date;
}

// ---- Product Unit ----

@ObjectType()
export class ProductUnit {
  @Field(() => ID)
  id: string;

  @Field()
  product_id: string;

  @Field()
  unit_name: string;

  @Field(() => Float)
  conversion_factor: number;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field({ nullable: true })
  barcode?: string;

  @Field()
  is_default: boolean;

  @Field()
  created_at: Date;
}

// ---- Product ----

@ObjectType()
export class Product {
  @Field(() => ID)
  id: string;

  @Field()
  tenant_id: string;

  @Field({ nullable: true })
  category_id?: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  short_description?: string;

  @Field({ nullable: true })
  thumbnail?: string;

  @Field({ nullable: true })
  thumbnail_url?: string;

  @Field(() => Float)
  base_price: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => Float, { nullable: true })
  compare_price?: number;

  @Field(() => Float)
  tax_rate: number;

  @Field()
  tax_inclusive: boolean;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field()
  base_unit: string;

  @Field()
  is_active: boolean;

  @Field()
  is_featured: boolean;

  @Field()
  allow_sell_when_out_of_stock: boolean;

  @Field()
  track_inventory: boolean;

  @Field(() => [String], { nullable: true })
  tags?: string[];

  @Field(() => Int)
  sort_order: number;

  @Field()
  created_at: Date;

  @Field()
  updated_at: Date;

  @Field(() => [ProductVariant], { nullable: true })
  variants?: ProductVariant[];

  @Field(() => [ProductImage], { nullable: true })
  images?: ProductImage[];

  @Field(() => [ProductUnit], { nullable: true })
  units?: ProductUnit[];

  @Field(() => Category, { nullable: true })
  category?: Category;
}

// ---- Paginated Response ----

@ObjectType()
export class PaginatedProducts {
  @Field(() => [Product])
  data: Product[];

  @Field(() => Int)
  total: number;

  @Field(() => Int)
  page: number;

  @Field(() => Int)
  limit: number;
}

// ---- Input Types ----

@InputType()
export class CreateProductInput {
  @Field()
  name: string;

  @Field({ nullable: true })
  category_id?: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  short_description?: string;

  @Field({ nullable: true })
  thumbnail?: string;

  @Field({ nullable: true })
  thumbnail_url?: string;

  @Field(() => Float)
  base_price: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => Float, { nullable: true })
  compare_price?: number;

  @Field(() => Float, { nullable: true, defaultValue: 0 })
  tax_rate?: number;

  @Field({ nullable: true, defaultValue: true })
  tax_inclusive?: boolean;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field({ nullable: true, defaultValue: 'cái' })
  base_unit?: string;

  @Field({ nullable: true, defaultValue: true })
  is_active?: boolean;

  @Field({ nullable: true, defaultValue: false })
  is_featured?: boolean;

  @Field({ nullable: true, defaultValue: false })
  allow_sell_when_out_of_stock?: boolean;

  @Field({ nullable: true, defaultValue: true })
  track_inventory?: boolean;

  @Field(() => [String], { nullable: true })
  tags?: string[];

  @Field(() => Int, { nullable: true, defaultValue: 0 })
  sort_order?: number;
}

@InputType()
export class UpdateProductInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  category_id?: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  short_description?: string;

  @Field({ nullable: true })
  thumbnail?: string;

  @Field({ nullable: true })
  thumbnail_url?: string;

  @Field(() => Float, { nullable: true })
  base_price?: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => Float, { nullable: true })
  compare_price?: number;

  @Field(() => Float, { nullable: true })
  tax_rate?: number;

  @Field({ nullable: true })
  tax_inclusive?: boolean;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field({ nullable: true })
  base_unit?: string;

  @Field({ nullable: true })
  is_active?: boolean;

  @Field({ nullable: true })
  is_featured?: boolean;

  @Field({ nullable: true })
  allow_sell_when_out_of_stock?: boolean;

  @Field({ nullable: true })
  track_inventory?: boolean;

  @Field(() => [String], { nullable: true })
  tags?: string[];

  @Field(() => Int, { nullable: true })
  sort_order?: number;
}

@InputType()
export class ProductFilterInput {
  @Field({ nullable: true })
  search?: string;

  @Field({ nullable: true })
  category_id?: string;

  @Field({ nullable: true })
  is_active?: boolean;

  @Field({ nullable: true })
  is_featured?: boolean;

  @Field(() => Float, { nullable: true })
  min_price?: number;

  @Field(() => Float, { nullable: true })
  max_price?: number;

  @Field(() => Int, { nullable: true, defaultValue: 1 })
  page?: number;

  @Field(() => Int, { nullable: true, defaultValue: 20 })
  limit?: number;
}

// ---- Variant Inputs ----

@InputType()
export class CreateVariantInput {
  @Field()
  product_id: string;

  @Field()
  name: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field({ nullable: true })
  image_url?: string;

  @Field({ nullable: true, defaultValue: true })
  is_active?: boolean;

  @Field(() => Int, { nullable: true, defaultValue: 0 })
  sort_order?: number;
}

@InputType()
export class UpdateVariantInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  sku?: string;

  @Field({ nullable: true })
  barcode?: string;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field(() => Float, { nullable: true })
  cost_price?: number;

  @Field(() => GraphQLJSON, { nullable: true })
  attributes?: Record<string, unknown>;

  @Field({ nullable: true })
  image_url?: string;

  @Field({ nullable: true })
  is_active?: boolean;

  @Field(() => Int, { nullable: true })
  sort_order?: number;
}

// ---- Category Inputs ----

@InputType()
export class CreateCategoryInput {
  @Field()
  name: string;

  @Field({ nullable: true })
  parent_id?: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  image_url?: string;

  @Field(() => Int, { nullable: true, defaultValue: 0 })
  sort_order?: number;

  @Field({ nullable: true, defaultValue: true })
  is_active?: boolean;
}

@InputType()
export class UpdateCategoryInput {
  @Field({ nullable: true })
  name?: string;

  @Field({ nullable: true })
  parent_id?: string;

  @Field({ nullable: true })
  slug?: string;

  @Field({ nullable: true })
  description?: string;

  @Field({ nullable: true })
  image_url?: string;

  @Field(() => Int, { nullable: true })
  sort_order?: number;

  @Field({ nullable: true })
  is_active?: boolean;
}

// ---- Unit Inputs ----

@InputType()
export class CreateUnitInput {
  @Field()
  product_id: string;

  @Field()
  unit_name: string;

  @Field(() => Float)
  conversion_factor: number;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field({ nullable: true })
  barcode?: string;

  @Field({ nullable: true, defaultValue: false })
  is_default?: boolean;
}

@InputType()
export class UpdateUnitInput {
  @Field({ nullable: true })
  unit_name?: string;

  @Field(() => Float, { nullable: true })
  conversion_factor?: number;

  @Field(() => Float, { nullable: true })
  price?: number;

  @Field({ nullable: true })
  barcode?: string;

  @Field({ nullable: true })
  is_default?: boolean;
}