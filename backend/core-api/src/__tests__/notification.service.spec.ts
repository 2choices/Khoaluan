import { Test, TestingModule } from '@nestjs/testing';
import { NotificationService } from '../notification/notification.service';
import { SupabaseService } from '../supabase/supabase.service';
import { ConfigService } from '@nestjs/config';
import {
  mockSupabaseService,
  mockSupabaseClient,
  mockConfigService,
  resetAllMocks,
} from './test-helpers';

describe('NotificationService', () => {
  let service: NotificationService;

  beforeEach(async () => {
    resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<NotificationService>(NotificationService);
  });

  describe('createNotification', () => {
    it('should insert notification into DB', async () => {
      const notification = {
        id: 'n1',
        title: 'Test',
        body: 'Test body',
        type: 'order_status',
      };

      mockSupabaseClient.single.mockResolvedValueOnce({
        data: notification,
        error: null,
      });

      const result = await service.createNotification({
        tenantId: 'tenant-1',
        userId: 'user-1',
        title: 'Test',
        body: 'Test body',
        type: 'order_status',
      });

      expect(result).toEqual(notification);
      expect(mockSupabaseClient.from).toHaveBeenCalledWith('notifications');
    });
  });

  describe('getUserNotifications', () => {
    it('should return paginated notifications', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: [{ id: 'n1' }, { id: 'n2' }],
        count: 2,
        error: null,
      });

      const result = await service.getUserNotifications('user-1', 1, 20);

      expect(result.data).toHaveLength(2);
      expect(result.total).toBe(2);
      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('user_id', 'user-1');
    });
  });

  describe('markAsRead', () => {
    it('should mark notification as read', async () => {
      mockSupabaseClient.eq
        .mockReturnValueOnce(mockSupabaseClient)
        .mockResolvedValueOnce({ error: null });

      const result = await service.markAsRead('user-1', 'n1');

      expect(result).toBe(true);
      expect(mockSupabaseClient.update).toHaveBeenCalledWith(
        expect.objectContaining({ is_read: true }),
      );
    });
  });

  describe('notifyOrderStatus', () => {
    it('should create notification with correct status message', async () => {
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: { id: 'n1', title: 'Cập nhật đơn hàng', body: 'Đơn hàng đã được xác nhận' },
        error: null,
      });

      const result = await service.notifyOrderStatus('tenant-1', 'user-1', 'ord-1', 'confirmed');

      expect(result).toBeDefined();
      expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
        expect.objectContaining({
          type: 'order_status',
          reference_id: 'ord-1',
          reference_type: 'order',
        }),
      );
    });
  });

  describe('sendPush', () => {
    it('should return null if Firebase not configured', async () => {
      mockConfigService.get.mockReturnValue(undefined);

      const result = await service.sendPush('token', 'Title', 'Body');

      expect(result).toBeNull();
    });
  });
});
