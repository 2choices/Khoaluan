import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  CreateWarehouseInput,
  CreateStockMovementInput,
  StocktakeInput,
  CreateBatchInput,
  InventoryFilterInput,
} from './dto/inventory.types';

@Injectable()
export class InventoryService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  // ==================== WAREHOUSES ====================

  async getWarehouses(tenantId: string) {
    const { data, error } = await this.db
      .from('warehouses')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('is_default', { ascending: false })
      .order('name');

    if (error) throw error;
    return data || [];
  }

  async createWarehouse(tenantId: string, input: CreateWarehouseInput) {
    const { data, error } = await this.db
      .from('warehouses')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateWarehouse(tenantId: string, id: string, input: Partial<CreateWarehouseInput>) {
    const { data, error } = await this.db
      .from('warehouses')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Warehouse not found');
    return data;
  }

  // ==================== INVENTORY ====================

  async getInventory(tenantId: string, filter: InventoryFilterInput = {}) {
    const page = filter.page || 1;
    const limit = filter.limit || 50;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('inventory')
      .select(
        '*, product:products(id, name, sku, barcode, base_unit), warehouse:warehouses(id, name)',
        { count: 'exact' },
      )
      .eq('tenant_id', tenantId);

    if (filter.warehouse_id) {
      query = query.eq('warehouse_id', filter.warehouse_id);
    }
    if (filter.product_id) {
      query = query.eq('product_id', filter.product_id);
    }
    if (filter.low_stock_only) {
      query = query.filter('quantity', 'lte', 'min_quantity');
    }

    query = query.range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;

    return { data: data || [], total: count || 0, page, limit };
  }

  async getProductStock(tenantId: string, productId: string) {
    const { data, error } = await this.db
      .from('inventory')
      .select('*, warehouse:warehouses(id, name)')
      .eq('tenant_id', tenantId)
      .eq('product_id', productId);

    if (error) throw error;
    return data || [];
  }

  // ==================== STOCK MOVEMENTS ====================

  async createMovement(tenantId: string, userId: string, input: CreateStockMovementInput) {
    const { data, error } = await this.db
      .from('stock_movements')
      .insert({
        ...input,
        tenant_id: tenantId,
        created_by: userId,
      })
      .select()
      .single();

    if (error) throw error;

    // Inventory update is handled by DB trigger (update_inventory_on_movement)
    await this.redis.delPattern(`inventory:${tenantId}:*`);
    return data;
  }

  async getMovements(
    tenantId: string,
    filters: {
      warehouse_id?: string;
      product_id?: string;
      movement_type?: string;
      page?: number;
      limit?: number;
    } = {},
  ) {
    const page = filters.page || 1;
    const limit = filters.limit || 50;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('stock_movements')
      .select(
        '*, product:products(id, name, sku), warehouse:warehouses(id, name)',
        { count: 'exact' },
      )
      .eq('tenant_id', tenantId);

    if (filters.warehouse_id) {
      query = query.eq('warehouse_id', filters.warehouse_id);
    }
    if (filters.product_id) {
      query = query.eq('product_id', filters.product_id);
    }
    if (filters.movement_type) {
      query = query.eq('movement_type', filters.movement_type);
    }

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;

    return { data: data || [], total: count || 0, page, limit };
  }

  // ==================== STOCKTAKE ====================

  async stocktake(tenantId: string, userId: string, input: StocktakeInput) {
    // Get current quantity
    const { data: inv } = await this.db
      .from('inventory')
      .select('quantity')
      .eq('tenant_id', tenantId)
      .eq('product_id', input.product_id)
      .eq('warehouse_id', input.warehouse_id)
      .maybeSingle();

    const currentQty = inv?.quantity || 0;
    const diff = input.actual_quantity - currentQty;

    if (diff === 0) return { adjusted: false, diff: 0 };

    // Create adjustment movement
    await this.createMovement(tenantId, userId, {
      product_id: input.product_id,
      variant_id: input.variant_id,
      warehouse_id: input.warehouse_id,
      movement_type: 'adjustment' as any,
      quantity: diff,
      reference_type: 'stocktake',
      note: input.note || `Kiểm kê: ${currentQty} → ${input.actual_quantity}`,
    });

    return { adjusted: true, diff, from: currentQty, to: input.actual_quantity };
  }

  // ==================== BATCHES ====================

  async getBatches(tenantId: string, productId: string, warehouseId?: string) {
    let query = this.db
      .from('stock_batches')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('product_id', productId)
      .order('expiry_date', { ascending: true, nullsFirst: false });

    if (warehouseId) {
      query = query.eq('warehouse_id', warehouseId);
    }

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }

  async createBatch(tenantId: string, input: CreateBatchInput) {
    const { data, error } = await this.db
      .from('stock_batches')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  // ==================== LOW STOCK ALERTS ====================

  async getLowStockAlerts(tenantId: string) {
    const cacheKey = `low-stock:${tenantId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const { data, error } = await this.db
      .from('inventory')
      .select('*, product:products(name), warehouse:warehouses(name)')
      .eq('tenant_id', tenantId)
      .filter('quantity', 'lte', 'min_quantity')
      .gt('min_quantity', 0);

    if (error) throw error;

    const alerts = (data || []).map((inv: any) => ({
      product_id: inv.product_id,
      product_name: inv.product?.name,
      warehouse_name: inv.warehouse?.name,
      current_quantity: inv.quantity,
      min_quantity: inv.min_quantity,
    }));

    await this.redis.set(cacheKey, alerts, 300);
    return alerts;
  }
}
