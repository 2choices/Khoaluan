import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class DashboardService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async getStats(tenantId: string, branchId?: string) {
    const cacheKey = `dashboard:${tenantId}:${branchId || 'all'}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return cached;

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // Today's orders
    let todayQuery = this.db
      .from('orders')
      .select('total_amount')
      .eq('tenant_id', tenantId)
      .in('status', ['confirmed', 'completed'])
      .eq('is_return', false)
      .gte('created_at', today.toISOString());

    if (branchId) todayQuery = todayQuery.eq('branch_id', branchId);
    const { data: todayOrders } = await todayQuery;

    // Yesterday's orders
    let yesterdayQuery = this.db
      .from('orders')
      .select('total_amount')
      .eq('tenant_id', tenantId)
      .in('status', ['confirmed', 'completed'])
      .eq('is_return', false)
      .gte('created_at', yesterday.toISOString())
      .lt('created_at', today.toISOString());

    if (branchId) yesterdayQuery = yesterdayQuery.eq('branch_id', branchId);
    const { data: yesterdayOrders } = await yesterdayQuery;

    const todayRevenue = (todayOrders || []).reduce((s: number, o: any) => s + o.total_amount, 0);
    const yesterdayRevenue = (yesterdayOrders || []).reduce((s: number, o: any) => s + o.total_amount, 0);
    const todayCount = (todayOrders || []).length;

    // Customers
    const { count: totalCustomers } = await this.db
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', tenantId);

    const { count: newCustomers } = await this.db
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', tenantId)
      .gte('created_at', today.toISOString());

    // Low stock
    const { count: lowStock } = await this.db
      .from('inventory')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', tenantId)
      .filter('quantity', 'lte', 'min_quantity')
      .gt('min_quantity', 0);

    const stats = {
      today_revenue: todayRevenue,
      today_orders: todayCount,
      today_average_order: todayCount > 0 ? todayRevenue / todayCount : 0,
      yesterday_revenue: yesterdayRevenue,
      revenue_change_percent:
        yesterdayRevenue > 0
          ? ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100
          : todayRevenue > 0
            ? 100
            : 0,
      total_customers: totalCustomers || 0,
      new_customers_today: newCustomers || 0,
      low_stock_count: lowStock || 0,
    };

    await this.redis.set(cacheKey, stats, 60); // Cache 1 min
    return stats;
  }

  async getTopProducts(tenantId: string, days = 30, limit = 10) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const { data } = await this.db
      .from('order_items')
      .select('product_id, product_name, quantity, total')
      .eq('tenant_id', tenantId)
      .gte('created_at', since.toISOString());

    // Aggregate
    const map = new Map<string, { product_name: string; quantity: number; revenue: number }>();
    for (const item of data || []) {
      const existing = map.get(item.product_id) || {
        product_name: item.product_name,
        quantity: 0,
        revenue: 0,
      };
      existing.quantity += Number(item.quantity);
      existing.revenue += Number(item.total);
      map.set(item.product_id, existing);
    }

    return Array.from(map.entries())
      .map(([product_id, v]) => ({
        product_id,
        product_name: v.product_name,
        quantity_sold: Math.round(v.quantity),
        revenue: v.revenue,
      }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, limit);
  }

  async getTopCustomers(tenantId: string, days = 30, limit = 10) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const { data } = await this.db
      .from('orders')
      .select('customer_id, total_amount, customers(full_name)')
      .eq('tenant_id', tenantId)
      .not('customer_id', 'is', null)
      .in('status', ['confirmed', 'completed'])
      .gte('created_at', since.toISOString());

    const map = new Map<string, { name: string; count: number; total: number }>();
    for (const order of data || []) {
      const existing = map.get(order.customer_id) || {
        name: (order as any).customers?.full_name || 'Unknown',
        count: 0,
        total: 0,
      };
      existing.count += 1;
      existing.total += Number(order.total_amount);
      map.set(order.customer_id, existing);
    }

    return Array.from(map.entries())
      .map(([customer_id, v]) => ({
        customer_id,
        customer_name: v.name,
        order_count: v.count,
        total_spent: v.total,
      }))
      .sort((a, b) => b.total_spent - a.total_spent)
      .slice(0, limit);
  }

  async getRevenueByDay(tenantId: string, days = 30) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const { data } = await this.db
      .from('orders')
      .select('total_amount, created_at')
      .eq('tenant_id', tenantId)
      .in('status', ['confirmed', 'completed'])
      .eq('is_return', false)
      .gte('created_at', since.toISOString())
      .order('created_at');

    const map = new Map<string, { revenue: number; count: number }>();
    for (const order of data || []) {
      const day = new Date(order.created_at).toISOString().split('T')[0];
      const existing = map.get(day) || { revenue: 0, count: 0 };
      existing.revenue += Number(order.total_amount);
      existing.count += 1;
      map.set(day, existing);
    }

    return Array.from(map.entries())
      .map(([period, v]) => ({
        period,
        revenue: v.revenue,
        order_count: v.count,
      }))
      .sort((a, b) => a.period.localeCompare(b.period));
  }
}
