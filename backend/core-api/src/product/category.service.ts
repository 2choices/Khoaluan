import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import { CreateCategoryInput, UpdateCategoryInput } from './dto/product.types';

@Injectable()
export class CategoryService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async findAll(tenantId: string) {
    const cacheKey = `categories:${tenantId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const { data, error } = await this.db
      .from('categories')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('sort_order')
      .order('name');

    if (error) throw error;

    // Build tree structure
    const tree = this.buildTree(data || []);
    await this.redis.set(cacheKey, tree, 1800);
    return tree;
  }

  async findById(tenantId: string, id: string) {
    const { data, error } = await this.db
      .from('categories')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error || !data) throw new NotFoundException('Category not found');
    return data;
  }

  async create(tenantId: string, input: CreateCategoryInput) {
    const { data, error } = await this.db
      .from('categories')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    await this.redis.del(`categories:${tenantId}`);
    return data;
  }

  async update(tenantId: string, id: string, input: UpdateCategoryInput) {
    const { data, error } = await this.db
      .from('categories')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Category not found');
    await this.redis.del(`categories:${tenantId}`);
    return data;
  }

  async remove(tenantId: string, id: string) {
    const { error } = await this.db
      .from('categories')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    await this.redis.del(`categories:${tenantId}`);
    return true;
  }

  /** Build a tree from flat category list */
  private buildTree(categories: any[]): any[] {
    const map = new Map<string, any>();
    const roots: any[] = [];

    for (const cat of categories) {
      map.set(cat.id, { ...cat, children: [] });
    }

    for (const cat of categories) {
      const node = map.get(cat.id)!;
      if (cat.parent_id && map.has(cat.parent_id)) {
        map.get(cat.parent_id)!.children.push(node);
      } else {
        roots.push(node);
      }
    }

    return roots;
  }
}
