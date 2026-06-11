import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Log an activity */
  async log(params: {
    tenantId: string;
    userId: string;
    action: string;
    entityType: string;
    entityId?: string;
    details?: Record<string, any>;
    ipAddress?: string;
  }) {
    const { error } = await this.db.from('activity_logs').insert({
      tenant_id: params.tenantId,
      user_id: params.userId,
      action: params.action,
      entity_type: params.entityType,
      entity_id: params.entityId,
      details: params.details || {},
      ip_address: params.ipAddress,
    });

    if (error) {
      this.logger.error('Failed to log activity', error.message);
    }
  }

  /** Get activity logs with filters */
  async getLogs(tenantId: string, filters: {
    userId?: string;
    action?: string;
    entityType?: string;
    entityId?: string;
    startDate?: string;
    endDate?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters.page || 1;
    const limit = filters.limit || 50;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('activity_logs')
      .select('*', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (filters.userId) query = query.eq('user_id', filters.userId);
    if (filters.action) query = query.eq('action', filters.action);
    if (filters.entityType) query = query.eq('entity_type', filters.entityType);
    if (filters.entityId) query = query.eq('entity_id', filters.entityId);
    if (filters.startDate) query = query.gte('created_at', filters.startDate);
    if (filters.endDate) query = query.lte('created_at', filters.endDate);

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  /** Get action types for filtering */
  async getActionTypes(tenantId: string) {
    const { data, error } = await this.db
      .from('activity_logs')
      .select('action')
      .eq('tenant_id', tenantId);

    if (error) throw error;
    return [...new Set((data || []).map((d: any) => d.action))];
  }
}
