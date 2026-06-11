import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ReportService {
  private readonly logger = new Logger(ReportService.name);

  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Revenue report */
  async getRevenueReport(tenantId: string, startDate: string, endDate: string, groupBy: 'day' | 'week' | 'month' = 'day') {
    const { data, error } = await this.db
      .from('orders')
      .select('total_amount, created_at, payment_method, status')
      .eq('tenant_id', tenantId)
      .in('status', ['completed', 'confirmed'])
      .gte('created_at', startDate)
      .lte('created_at', endDate)
      .order('created_at', { ascending: true });

    if (error) throw error;

    const grouped = this.groupByPeriod(data || [], groupBy);
    const totalRevenue = (data || []).reduce((s: number, o: any) => s + (o.total_amount || 0), 0);
    const orderCount = (data || []).length;

    return {
      summary: { totalRevenue, orderCount, averageOrderValue: orderCount ? Math.round(totalRevenue / orderCount) : 0 },
      details: grouped,
      period: { startDate, endDate, groupBy },
    };
  }

  /** Product sales report */
  async getProductReport(tenantId: string, startDate: string, endDate: string, limit = 50) {
    const { data: orders, error: orderErr } = await this.db
      .from('orders')
      .select('id')
      .eq('tenant_id', tenantId)
      .in('status', ['completed', 'confirmed'])
      .gte('created_at', startDate)
      .lte('created_at', endDate);

    if (orderErr) throw orderErr;

    const orderIds = (orders || []).map((o: any) => o.id);
    if (orderIds.length === 0) return { products: [], period: { startDate, endDate } };

    const { data: items, error: itemErr } = await this.db
      .from('order_items')
      .select('product_id, product_name, quantity, subtotal')
      .in('order_id', orderIds);

    if (itemErr) throw itemErr;

    // Aggregate by product
    const productMap = new Map<string, { productId: string; name: string; quantity: number; revenue: number }>();
    (items || []).forEach((item: any) => {
      const existing = productMap.get(item.product_id);
      if (existing) {
        existing.quantity += item.quantity;
        existing.revenue += item.subtotal;
      } else {
        productMap.set(item.product_id, {
          productId: item.product_id,
          name: item.product_name,
          quantity: item.quantity,
          revenue: item.subtotal,
        });
      }
    });

    const products = Array.from(productMap.values())
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, limit);

    return { products, period: { startDate, endDate } };
  }

  /** Inventory report */
  async getInventoryReport(tenantId: string) {
    const { data, error } = await this.db
      .from('inventory')
      .select('*, products(name, sku)')
      .eq('tenant_id', tenantId)
      .order('quantity', { ascending: true });

    if (error) throw error;

    const items = data || [];
    const lowStock = items.filter((i: any) => i.quantity <= (i.min_quantity || 10));
    const outOfStock = items.filter((i: any) => i.quantity <= 0);
    const totalValue = items.reduce((s: number, i: any) => s + (i.quantity * (i.cost_price || 0)), 0);

    return {
      totalItems: items.length,
      lowStockCount: lowStock.length,
      outOfStockCount: outOfStock.length,
      totalValue,
      lowStockItems: lowStock.slice(0, 50),
      outOfStockItems: outOfStock,
    };
  }

  /** Customer report */
  async getCustomerReport(tenantId: string, startDate: string, endDate: string) {
    const { count: newCustomerCount, error: err1 } = await this.db
      .from('customers')
      .select('id', { count: 'exact', head: true })
      .eq('tenant_id', tenantId)
      .gte('created_at', startDate)
      .lte('created_at', endDate);

    const { data: orders, error: err2 } = await this.db
      .from('orders')
      .select('customer_id, total_amount')
      .eq('tenant_id', tenantId)
      .in('status', ['completed', 'confirmed'])
      .gte('created_at', startDate)
      .lte('created_at', endDate)
      .not('customer_id', 'is', null);

    if (err1) throw err1;
    if (err2) throw err2;

    // Count unique customers who ordered
    const uniqueCustomers = new Set((orders || []).map((o: any) => o.customer_id));

    return {
      newCustomers: newCustomerCount || 0,
      activeCustomers: uniqueCustomers.size,
      totalOrders: (orders || []).length,
      period: { startDate, endDate },
    };
  }

  /** Export data as JSON (frontend converts to Excel/PDF) */
  async exportReport(tenantId: string, reportType: string, startDate: string, endDate: string) {
    switch (reportType) {
      case 'revenue':
        return this.getRevenueReport(tenantId, startDate, endDate);
      case 'products':
        return this.getProductReport(tenantId, startDate, endDate, 500);
      case 'inventory':
        return this.getInventoryReport(tenantId);
      case 'customers':
        return this.getCustomerReport(tenantId, startDate, endDate);
      default:
        return { error: 'Unknown report type' };
    }
  }

  private groupByPeriod(orders: any[], groupBy: 'day' | 'week' | 'month') {
    const groups = new Map<string, { period: string; revenue: number; orderCount: number }>();

    orders.forEach((order) => {
      const date = new Date(order.created_at);
      let key: string;

      if (groupBy === 'day') {
        key = date.toISOString().split('T')[0];
      } else if (groupBy === 'week') {
        const weekStart = new Date(date);
        weekStart.setDate(date.getDate() - date.getDay());
        key = `W-${weekStart.toISOString().split('T')[0]}`;
      } else {
        key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
      }

      const existing = groups.get(key);
      if (existing) {
        existing.revenue += order.total_amount || 0;
        existing.orderCount++;
      } else {
        groups.set(key, { period: key, revenue: order.total_amount || 0, orderCount: 1 });
      }
    });

    return Array.from(groups.values());
  }
}
