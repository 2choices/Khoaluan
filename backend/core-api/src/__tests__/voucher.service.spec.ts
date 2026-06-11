import { Test, TestingModule } from '@nestjs/testing';
import { VoucherService } from '../voucher/voucher.service';
import { SupabaseService } from '../supabase/supabase.service';
import {
  mockSupabaseService,
  mockSupabaseClient,
  resetAllMocks,
} from './test-helpers';

describe('VoucherService', () => {
  let service: VoucherService;

  beforeEach(async () => {
    resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VoucherService,
        { provide: SupabaseService, useValue: mockSupabaseService },
      ],
    }).compile();

    service = module.get<VoucherService>(VoucherService);
  });

  describe('create', () => {
    it('should create a voucher with uppercase code', async () => {
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: { id: 'v1', code: 'SALE50', type: 'percentage', value: 50 },
        error: null,
      });

      const result = await service.create('tenant-1', {
        code: 'sale50',
        name: 'Sale 50%',
        type: 'percentage',
        value: 50,
        starts_at: '2026-01-01',
        ends_at: '2026-12-31',
      });

      expect(result.code).toBe('SALE50');
      expect(mockSupabaseClient.insert).toHaveBeenCalledWith(
        expect.objectContaining({ code: 'SALE50' }),
      );
    });
  });

  describe('validateCode', () => {
    it('should validate and calculate percentage discount', async () => {
      const voucher = {
        id: 'v1',
        code: 'SALE20',
        type: 'percentage',
        value: 20,
        max_discount: 50000,
        min_order_amount: 100000,
        usage_limit: 100,
        usage_count: 5,
        per_customer_limit: 1,
        start_date: '2025-01-01',
        end_date: '2027-12-31',
        status: 'active',
      };

      mockSupabaseClient.single.mockResolvedValueOnce({
        data: voucher,
        error: null,
      });

      const result = await service.validateCode('tenant-1', 'SALE20', 200000);

      expect(result.voucher.id).toBe('v1');
      expect(result.discount).toBe(40000); // 200000 * 20% = 40000
    });

    it('should cap discount at max_discount', async () => {
      const voucher = {
        id: 'v1',
        code: 'BIG50',
        type: 'percentage',
        value: 50,
        max_discount: 30000,
        min_order_amount: 0,
        usage_limit: null,
        usage_count: 0,
        per_customer_limit: null,
        start_date: '2025-01-01',
        end_date: '2027-12-31',
        status: 'active',
      };

      mockSupabaseClient.single.mockResolvedValueOnce({
        data: voucher,
        error: null,
      });

      const result = await service.validateCode('tenant-1', 'BIG50', 200000);

      expect(result.discount).toBe(30000); // capped at max_discount
    });

    it('should throw for expired voucher', async () => {
      const voucher = {
        id: 'v1',
        code: 'OLD',
        type: 'percentage',
        value: 10,
        start_date: '2020-01-01',
        end_date: '2020-12-31',
        status: 'active',
      };

      mockSupabaseClient.single.mockResolvedValueOnce({
        data: voucher,
        error: null,
      });

      await expect(
        service.validateCode('tenant-1', 'OLD', 100000),
      ).rejects.toThrow('Mã giảm giá đã hết hạn');
    });

    it('should throw for invalid code', async () => {
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: null,
        error: { message: 'not found' },
      });

      await expect(
        service.validateCode('tenant-1', 'INVALID', 100000),
      ).rejects.toThrow('Mã giảm giá không hợp lệ');
    });
  });

  describe('findAll', () => {
    it('should return paginated vouchers', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: [{ id: 'v1' }],
        count: 1,
        error: null,
      });

      const result = await service.findAll('tenant-1');

      expect(result.data).toHaveLength(1);
      expect(result.total).toBe(1);
    });

    it('should filter by active status', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: [],
        count: 0,
        error: null,
      });

      await service.findAll('tenant-1', 1, 20, true);

      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('status', 'active');
    });
  });
});
