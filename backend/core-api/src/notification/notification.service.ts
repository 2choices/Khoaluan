import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(
    private config: ConfigService,
    private supabase: SupabaseService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Send push notification via FCM */
  async sendPush(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ) {
    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID');
    if (!projectId) {
      this.logger.warn('Firebase not configured, skipping push');
      return null;
    }

    try {
      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            // In production, use service account auth
          },
          body: JSON.stringify({
            message: {
              token: fcmToken,
              notification: { title, body },
              data: data || {},
            },
          }),
        },
      );

      return await response.json();
    } catch (err) {
      this.logger.error('FCM push failed', (err as Error).message);
      return null;
    }
  }

  /** Save notification to DB + optionally push */
  async createNotification(params: {
    tenantId: string;
    userId: string;
    title: string;
    body: string;
    type: string;
    referenceId?: string;
    referenceType?: string;
  }) {
    const { data, error } = await this.db
      .from('notifications')
      .insert({
        tenant_id: params.tenantId,
        user_id: params.userId,
        title: params.title,
        body: params.body,
        type: params.type,
        reference_id: params.referenceId,
        reference_type: params.referenceType,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  /** Get user notifications */
  async getUserNotifications(userId: string, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    const { data, count, error } = await this.db
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  /** Get unread count for user */
  async getUnreadCount(userId: string): Promise<number> {
    const { count, error } = await this.db
      .from('notifications')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);
    if (error) throw error;
    return count || 0;
  }

  /** Broadcast a notification to all users (or all customers of a tenant) */
  async broadcast(params: {
    tenantId: string;
    title: string;
    body: string;
    type?: string;
    audience?: 'all' | 'customers' | 'staff';
  }) {
    const audience = params.audience || 'customers';
    let userQuery = this.db.from('users').select('id').eq('tenant_id', params.tenantId);
    if (audience === 'customers') {
      userQuery = userQuery.eq('role', 'customer');
    } else if (audience === 'staff') {
      userQuery = userQuery.in('role', ['admin', 'manager', 'staff']);
    }
    const { data: users, error: userErr } = await userQuery;
    if (userErr) throw userErr;
    if (!users || users.length === 0) return { sent: 0 };

    const rows = users.map((u: { id: string }) => ({
      tenant_id: params.tenantId,
      user_id: u.id,
      title: params.title,
      body: params.body,
      type: params.type || 'announcement',
      is_read: false,
    }));
    const { error } = await this.db.from('notifications').insert(rows);
    if (error) throw error;
    return { sent: rows.length };
  }

  /** Mark notification as read */
  async markAsRead(userId: string, notificationId: string) {
    const { error } = await this.db
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('user_id', userId)
      .eq('id', notificationId);

    if (error) throw error;
    return true;
  }

  /** Mark all as read */
  async markAllAsRead(userId: string) {
    const { error } = await this.db
      .from('notifications')
      .update({ is_read: true, read_at: new Date().toISOString() })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
    return true;
  }

  /** Notify order status change */
  async notifyOrderStatus(tenantId: string, userId: string, orderId: string, status: string) {
    const statusMessages: Record<string, string> = {
      confirmed: 'Đơn hàng đã được xác nhận',
      processing: 'Đơn hàng đang được xử lý',
      completed: 'Đơn hàng đã hoàn thành',
      cancelled: 'Đơn hàng đã bị hủy',
      returned: 'Đơn hàng đã được hoàn trả',
    };

    return this.createNotification({
      tenantId,
      userId,
      title: 'Cập nhật đơn hàng',
      body: statusMessages[status] || `Trạng thái đơn hàng: ${status}`,
      type: 'order_status',
      referenceId: orderId,
      referenceType: 'order',
    });
  }
}
