import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class CatalogService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Public product listing (for Customer App) */
  async getProducts(
    tenantId: string,
    opts: {
      search?: string;
      categoryId?: string;
      featured?: boolean;
      page?: number;
      limit?: number;
    } = {},
  ) {
    const page = opts.page || 1;
    const limit = opts.limit || 20;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('products')
      .select(
        'id, name, slug, base_price, compare_price, base_unit, is_featured, tags, category:categories(id, name), images:product_images(url, thumbnail_url, is_primary), variants:product_variants(id, name, price, attributes, is_active)',
        { count: 'exact' },
      )
      .eq('tenant_id', tenantId)
      .eq('is_active', true);

    if (opts.search) query = query.ilike('name', `%${opts.search}%`);
    if (opts.categoryId) query = query.eq('category_id', opts.categoryId);
    if (opts.featured) query = query.eq('is_featured', true);

    query = query.order('sort_order').range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  async getProductDetail(tenantId: string, productId: string) {
    const cacheKey = `catalog:product:${productId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const { data, error } = await this.db
      .from('products')
      .select(
        '*, category:categories(id, name), images:product_images(*), variants:product_variants(*), units:product_units(*)',
      )
      .eq('tenant_id', tenantId)
      .eq('id', productId)
      .eq('is_active', true)
      .single();

    if (error || !data) return null;

    await this.redis.set(cacheKey, data, 300);
    return data;
  }

  /** Public categories (tree) */
  async getCategories(tenantId: string) {
    const cacheKey = `catalog:categories:${tenantId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const { data, error } = await this.db
      .from('categories')
      .select('id, name, slug, image_url, parent_id, sort_order')
      .eq('tenant_id', tenantId)
      .eq('is_active', true)
      .order('sort_order');

    if (error) throw error;

    const tree = this.buildTree(data || []);
    await this.redis.set(cacheKey, tree, 1800);
    return tree;
  }

  private buildTree(items: any[]): any[] {
    const map = new Map<string, any>();
    const roots: any[] = [];
    for (const item of items) map.set(item.id, { ...item, children: [] });
    for (const item of items) {
      const node = map.get(item.id)!;
      if (item.parent_id && map.has(item.parent_id)) {
        map.get(item.parent_id)!.children.push(node);
      } else {
        roots.push(node);
      }
    }
    return roots;
  }
}
