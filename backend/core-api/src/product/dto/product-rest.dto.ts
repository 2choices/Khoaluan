import {
  IsArray,
  IsBoolean,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateProductRestDto {
  @IsString()
  name: string;

  @IsOptional()
  @IsString()
  category_id?: string;

  @IsOptional()
  @IsString()
  slug?: string;

  @IsOptional()
  @IsString()
  sku?: string;

  @IsOptional()
  @IsString()
  barcode?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  short_description?: string;

  @IsOptional()
  @IsString()
  image_url?: string;

  @IsNumber()
  base_price: number;

  @IsOptional()
  @IsNumber()
  cost_price?: number;

  @IsOptional()
  @IsNumber()
  compare_price?: number;

  @IsOptional()
  @IsNumber()
  tax_rate?: number;

  @IsOptional()
  @IsBoolean()
  tax_inclusive?: boolean;

  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  base_unit?: string;

  @IsOptional()
  @IsBoolean()
  is_active?: boolean;

  @IsOptional()
  @IsBoolean()
  is_featured?: boolean;

  @IsOptional()
  @IsBoolean()
  allow_sell_when_out_of_stock?: boolean;

  @IsOptional()
  @IsBoolean()
  track_inventory?: boolean;

  @IsOptional()
  @IsArray()
  tags?: string[];

  @IsOptional()
  @IsNumber()
  sort_order?: number;
}

export class UpdateProductRestDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  category_id?: string;

  @IsOptional()
  @IsString()
  slug?: string;

  @IsOptional()
  @IsString()
  sku?: string;

  @IsOptional()
  @IsString()
  barcode?: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  short_description?: string;

  @IsOptional()
  @IsString()
  image_url?: string;

  @IsOptional()
  @IsNumber()
  base_price?: number;

  @IsOptional()
  @IsNumber()
  cost_price?: number;

  @IsOptional()
  @IsNumber()
  compare_price?: number;

  @IsOptional()
  @IsNumber()
  tax_rate?: number;

  @IsOptional()
  @IsBoolean()
  tax_inclusive?: boolean;

  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;

  @IsOptional()
  @IsString()
  base_unit?: string;

  @IsOptional()
  @IsBoolean()
  is_active?: boolean;

  @IsOptional()
  @IsBoolean()
  is_featured?: boolean;

  @IsOptional()
  @IsBoolean()
  allow_sell_when_out_of_stock?: boolean;

  @IsOptional()
  @IsBoolean()
  track_inventory?: boolean;

  @IsOptional()
  @IsArray()
  tags?: string[];

  @IsOptional()
  @IsNumber()
  sort_order?: number;
}