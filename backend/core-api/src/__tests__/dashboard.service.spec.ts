import { Test, TestingModule } from '@nestjs/testing';
import { DashboardService } from '../dashboard/dashboard.service';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  mockSupabaseService,
  mockSupabaseClient,
  mockRedisService,
  resetAllMocks,
} from './test-helpers';

describe('DashboardService', () => {
  let service: DashboardService;

  beforeEach(async () => {
    resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<DashboardService>(DashboardService);
  });

  describe('getTopProducts', () => {
    it('should return top selling products', async () => {
      mockSupabaseClient.gte.mockResolvedValueOnce({
        data: [
          { product_id: 'p1', product_name: 'SP A', quantity: 100, total: 5000000 },
          { product_id: 'p2', product_name: 'SP B', quantity: 80, total: 4000000 },
        ],
        error: null,
      });

      const result = await service.getTopProducts('tenant-1', 10);

      expect(result).toHaveLength(2);
    });
  });

  describe('getTopCustomers', () => {
    it('should return top customers by spending', async () => {
      mockSupabaseClient.gte.mockResolvedValueOnce({
        data: [
          { customer_id: 'c1', total_amount: 10000000, customers: { full_name: 'KH A' } },
        ],
        error: null,
      });

      const result = await service.getTopCustomers('tenant-1', 10);

      expect(result).toHaveLength(1);
    });
  });
});
