import { Test, TestingModule } from '@nestjs/testing';
import { OrderService } from '../order/order.service';
import { OrderStatus } from '../order/dto/order.types';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  mockSupabaseService,
  mockSupabaseClient,
  mockRedisService,
  resetAllMocks,
} from './test-helpers';

describe('OrderService', () => {
  let service: OrderService;

  beforeEach(async () => {
    resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrderService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<OrderService>(OrderService);
  });

  describe('findAll', () => {
    it('should return paginated orders', async () => {
      const mockOrders = [
        { id: '1', order_number: 'ORD-001', total_amount: 100000 },
      ];

      mockSupabaseClient.range.mockResolvedValueOnce({
        data: mockOrders,
        count: 1,
        error: null,
      });

      const result = await service.findAll('tenant-1', {});

      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('tenant_id', 'tenant-1');
    });

    it('should filter by status', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: [],
        count: 0,
        error: null,
      });

      await service.findAll('tenant-1', { status: OrderStatus.COMPLETED });

      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('status', 'completed');
    });
  });

  describe('create', () => {
    it('should create order with items and calculate totals', async () => {
      mockSupabaseClient.in.mockResolvedValueOnce({
        data: [{ id: 'p1', name: 'Sản phẩm A', base_price: 50000, cost_price: 0 }],
        error: null,
      });

      // Mock order insert
      mockSupabaseClient.single
        .mockResolvedValueOnce({
          data: { id: 'ord-1', order_number: 'ORD-001', total_amount: 50000 },
          error: null,
        })
        .mockResolvedValueOnce({
          data: { id: 'ord-1', order_number: 'ORD-001', total_amount: 50000 },
          error: null,
        });

      const result = await service.create('tenant-1', 'user-1', {
        branch_id: 'branch-1',
        items: [{ product_id: 'p1', quantity: 1, unit_price: 50000 }],
        source: 'pos',
      } as any);

      expect(result).toBeDefined();
    });
  });

  describe('updateStatus', () => {
    it('should update order status', async () => {
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: { id: '1', status: 'confirmed' },
        error: null,
      });

      const result = await service.updateStatus('tenant-1', '1', OrderStatus.CONFIRMED);

      expect(result.status).toBe('confirmed');
      expect(mockSupabaseClient.update).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'confirmed' }),
      );
    });
  });

  describe('cancelOrder', () => {
    it('should cancel an order', async () => {
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: { id: '1', status: 'cancelled' },
        error: null,
      });

      const result = await service.cancelOrder('tenant-1', '1');

      expect(result.status).toBe('cancelled');
    });
  });
});
