import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class CashBookService {
  private readonly logger = new Logger(CashBookService.name);

  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Create cash book entry */
  async createEntry(tenantId: string, params: {
    branchId: string;
    type: 'income' | 'expense';
    category: string;
    amount: number;
    description?: string;
    referenceId?: string;
    referenceType?: string;
    createdBy: string;
  }) {
    const { data, error } = await this.db
      .from('cash_book_entries')
      .insert({
        tenant_id: tenantId,
        branch_id: params.branchId,
        type: params.type,
        category: params.category,
        amount: params.amount,
        description: params.description,
        reference_id: params.referenceId,
        reference_type: params.referenceType,
        created_by: params.createdBy,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** List entries with filters */
  async findAll(tenantId: string, filters: {
    branchId?: string;
    type?: 'income' | 'expense';
    category?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('cash_book_entries')
      .select('*', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (filters.branchId) query = query.eq('branch_id', filters.branchId);
    if (filters.type) query = query.eq('type', filters.type);
    if (filters.category) query = query.eq('category', filters.category);
    if (filters.startDate) query = query.gte('created_at', filters.startDate);
    if (filters.endDate) query = query.lte('created_at', filters.endDate);

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  /** Get summary for a period */
  async getSummary(tenantId: string, branchId: string, startDate: string, endDate: string) {
    const { data, error } = await this.db
      .from('cash_book_entries')
      .select('type, amount')
      .eq('tenant_id', tenantId)
      .eq('branch_id', branchId)
      .gte('created_at', startDate)
      .lte('created_at', endDate);

    if (error) throw error;

    let totalIncome = 0;
    let totalExpense = 0;
    (data || []).forEach((entry: any) => {
      if (entry.type === 'income') totalIncome += entry.amount;
      else totalExpense += entry.amount;
    });

    return {
      totalIncome,
      totalExpense,
      balance: totalIncome - totalExpense,
      period: { startDate, endDate },
    };
  }

  /** Get categories used */
  async getCategories(tenantId: string) {
    const { data, error } = await this.db
      .from('cash_book_entries')
      .select('category')
      .eq('tenant_id', tenantId);

    if (error) throw error;

    const categories = [...new Set((data || []).map((d: any) => d.category))];
    return categories;
  }

  /** Update entry */
  async update(tenantId: string, id: string, params: Record<string, any>) {
    const { data, error } = await this.db
      .from('cash_book_entries')
      .update(params)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** Delete entry */
  async delete(tenantId: string, id: string) {
    const { error } = await this.db
      .from('cash_book_entries')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    return true;
  }
}
