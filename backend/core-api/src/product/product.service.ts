import { Injectable, NotFoundException, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  CreateProductInput,
  UpdateProductInput,
  ProductFilterInput,
  CreateVariantInput,
  UpdateVariantInput,
  CreateUnitInput,
  UpdateUnitInput,
} from './dto/product.types';

@Injectable()
export class ProductService {
  private readonly logger = new Logger(ProductService.name);

  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  private cleanObject<T extends Record<string, any>>(obj: T): T {
    return Object.fromEntries(
      Object.entries(obj).filter(([, value]) => value !== undefined),
    ) as T;
  }

  private extractImageUrl(input: any): string | undefined {
    const value = input?.image_url;
    if (typeof value !== 'string') return undefined;
    const trimmed = value.trim();
    return trimmed.length === 0 ? undefined : trimmed;
  }

  private buildProductPayload(input: any) {
    return this.cleanObject({
      name: input.name,
      category_id: input.category_id,
      slug: input.slug,
      sku: input.sku,
      barcode: input.barcode,
      description: input.description,
      short_description: input.short_description,
      base_price: input.base_price,
      cost_price: input.cost_price,
      compare_price: input.compare_price,
      tax_rate: input.tax_rate,
      tax_inclusive: input.tax_inclusive,
      attributes: input.attributes,
      base_unit: input.base_unit,
      is_active: input.is_active,
      is_featured: input.is_featured,
      allow_sell_when_out_of_stock: input.allow_sell_when_out_of_stock,
      track_inventory: input.track_inventory,
      tags: input.tags,
      sort_order: input.sort_order,
    });
  }

  async upsertPrimaryImage(
    tenantId: string,
    productId: string,
    imageUrl: string,
  ) {
    const normalizedUrl = imageUrl.trim();
    if (normalizedUrl.length === 0) return null;

    const { data: existing, error: existingError } = await this.db
      .from('product_images')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('product_id', productId)
      .eq('is_primary', true)
      .maybeSingle();

    if (existingError) throw existingError;

    if (existing) {
      const { data, error } = await this.db
        .from('product_images')
        .update({
          url: normalizedUrl,
          thumbnail_url: normalizedUrl,
          is_primary: true,
          sort_order: 0,
        })
        .eq('tenant_id', tenantId)
        .eq('id', existing.id)
        .select()
        .single();

      if (error) throw error;

      await this.redis.del(`product:${tenantId}:${productId}`);
      await this.redis.delPattern(`product:${tenantId}:*`);
      return data;
    }

    const { data, error } = await this.db
      .from('product_images')
      .insert({
        tenant_id: tenantId,
        product_id: productId,
        url: normalizedUrl,
        thumbnail_url: normalizedUrl,
        is_primary: true,
        sort_order: 0,
      })
      .select()
      .single();

    if (error) throw error;

    await this.redis.del(`product:${tenantId}:${productId}`);
    await this.redis.delPattern(`product:${tenantId}:*`);
    return data;
  }

  async findAll(tenantId: string, filter: ProductFilterInput = {}) {
    const page = filter.page || 1;
    const limit = filter.limit || 20;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('products')
      .select('*, category:categories(*), images:product_images(*)', {
        count: 'exact',
      })
      .eq('tenant_id', tenantId);

    if (filter.search) {
      query = query.ilike('name', `%${filter.search}%`);
    }
    if (filter.category_id) {
      query = query.eq('category_id', filter.category_id);
    }
    if (filter.is_active !== undefined) {
      query = query.eq('is_active', filter.is_active);
    }
    if (filter.is_featured !== undefined) {
      query = query.eq('is_featured', filter.is_featured);
    }
    if (filter.min_price !== undefined) {
      query = query.gte('base_price', filter.min_price);
    }
    if (filter.max_price !== undefined) {
      query = query.lte('base_price', filter.max_price);
    }

    query = query
      .order('sort_order')
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;

    return { data: data || [], total: count || 0, page, limit };
  }

  async findById(tenantId: string, id: string) {
    const cacheKey = `product:${tenantId}:${id}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const { data, error } = await this.db
      .from('products')
      .select(
        '*, category:categories(*), variants:product_variants(*), images:product_images(*), units:product_units(*)',
      )
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error || !data) throw new NotFoundException('Product not found');

    await this.redis.set(cacheKey, data, 600);
    return data;
  }

  async findByBarcode(tenantId: string, barcode: string) {
    const { data } = await this.db
      .from('products')
      .select('*, variants:product_variants(*)')
      .eq('tenant_id', tenantId)
      .eq('barcode', barcode)
      .maybeSingle();

    if (!data) {
      const { data: variant } = await this.db
        .from('product_variants')
        .select('*, product:products(*)')
        .eq('tenant_id', tenantId)
        .eq('barcode', barcode)
        .maybeSingle();

      if (!variant) throw new NotFoundException('Product not found by barcode');
      return variant.product;
    }

    return data;
  }

  async create(
    tenantId: string,
    input: CreateProductInput & { image_url?: string },
  ) {
    const imageUrl = this.extractImageUrl(input);

    const payload = this.cleanObject({
      ...this.buildProductPayload(input),
      tenant_id: tenantId,
    });

    const { data, error } = await this.db
      .from('products')
      .insert(payload)
      .select()
      .single();

    if (error) throw error;

    if (imageUrl) {
      await this.upsertPrimaryImage(tenantId, data.id, imageUrl);
    }

    await this.redis.delPattern(`product:${tenantId}:*`);
    return this.findById(tenantId, data.id);
  }

  async update(
    tenantId: string,
    id: string,
    input: UpdateProductInput & { image_url?: string },
  ) {
    try {
      this.logger.debug(
        `UPDATE PRODUCT tenantId=${tenantId} id=${id} input=${JSON.stringify(input)}`,
      );

      const { data: existing, error: existingError } = await this.db
        .from('products')
        .select('id, tenant_id')
        .eq('tenant_id', tenantId)
        .eq('id', id)
        .maybeSingle();

      if (existingError) {
        this.logger.error(`existingError: ${JSON.stringify(existingError)}`);
        throw existingError;
      }

      if (!existing) {
        throw new NotFoundException(
          `Product not found (tenantId=${tenantId}, id=${id})`,
        );
      }

      const imageUrl = this.extractImageUrl(input);

      const payload = this.cleanObject({
        ...this.buildProductPayload(input),
        updated_at: new Date().toISOString(),
      });

      this.logger.debug(`UPDATE PAYLOAD: ${JSON.stringify(payload)}`);
      this.logger.debug(`IMAGE URL: ${imageUrl ?? 'null'}`);

      const { error } = await this.db
        .from('products')
        .update(payload)
        .eq('tenant_id', tenantId)
        .eq('id', id);

      if (error) {
        this.logger.error(`products.update error: ${JSON.stringify(error)}`);
        throw error;
      }

      if (imageUrl) {
        await this.upsertPrimaryImage(tenantId, id, imageUrl);
      }

      await this.redis.del(`product:${tenantId}:${id}`);
      await this.redis.delPattern(`product:${tenantId}:*`);
      return this.findById(tenantId, id);
    } catch (e) {
      this.logger.error(
        `UPDATE PRODUCT FAILED: ${(e as Error).message}`,
        (e as Error).stack,
      );
      throw e;
    }
  }

  async remove(tenantId: string, id: string) {
    const { error } = await this.db
      .from('products')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    await this.redis.del(`product:${tenantId}:${id}`);
    await this.redis.delPattern(`product:${tenantId}:*`);
    return true;
  }

  async findVariantsByProduct(tenantId: string, productId: string) {
    const { data, error } = await this.db
      .from('product_variants')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('product_id', productId)
      .order('sort_order');

    if (error) throw error;
    return data || [];
  }

  async createVariant(tenantId: string, input: CreateVariantInput) {
    const { data, error } = await this.db
      .from('product_variants')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    await this.redis.del(`product:${tenantId}:${input.product_id}`);
    return data;
  }

  async updateVariant(
    tenantId: string,
    id: string,
    input: UpdateVariantInput,
  ) {
    const { data, error } = await this.db
      .from('product_variants')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Variant not found');
    await this.redis.delPattern(`product:${tenantId}:*`);
    return data;
  }

  async removeVariant(tenantId: string, id: string) {
    const { error } = await this.db
      .from('product_variants')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    await this.redis.delPattern(`product:${tenantId}:*`);
    return true;
  }

  async findUnitsByProduct(tenantId: string, productId: string) {
    const { data, error } = await this.db
      .from('product_units')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('product_id', productId);

    if (error) throw error;
    return data || [];
  }

  async createUnit(tenantId: string, input: CreateUnitInput) {
    const { data, error } = await this.db
      .from('product_units')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    await this.redis.del(`product:${tenantId}:${input.product_id}`);
    return data;
  }

  async updateUnit(tenantId: string, id: string, input: UpdateUnitInput) {
    const { data, error } = await this.db
      .from('product_units')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Unit not found');
    await this.redis.delPattern(`product:${tenantId}:*`);
    return data;
  }

  async removeUnit(tenantId: string, id: string) {
    const { error } = await this.db
      .from('product_units')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    await this.redis.delPattern(`product:${tenantId}:*`);
    return true;
  }

  async addImage(
    tenantId: string,
    productId: string,
    imageData: {
      url: string;
      thumbnail_url?: string;
      small_url?: string;
      alt_text?: string;
      is_primary?: boolean;
    },
  ) {
    const { data, error } = await this.db
      .from('product_images')
      .insert({ ...imageData, product_id: productId, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    await this.redis.del(`product:${tenantId}:${productId}`);
    return data;
  }

  async removeImage(tenantId: string, imageId: string) {
    const { error } = await this.db
      .from('product_images')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', imageId);

    if (error) throw error;
    await this.redis.delPattern(`product:${tenantId}:*`);
    return true;
  }
}