import { Test, TestingModule } from '@nestjs/testing';
import { ProductService } from '../product/product.service';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  mockSupabaseService,
  mockSupabaseClient,
  mockRedisService,
  resetAllMocks,
} from './test-helpers';

describe('ProductService', () => {
  let service: ProductService;

  beforeEach(async () => {
    resetAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ProductService,
        { provide: SupabaseService, useValue: mockSupabaseService },
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    service = module.get<ProductService>(ProductService);
  });

  describe('findAll', () => {
    it('should return paginated products', async () => {
      const mockProducts = [
        { id: '1', name: 'Product 1', price: 10000 },
        { id: '2', name: 'Product 2', price: 20000 },
      ];

      mockSupabaseClient.range.mockResolvedValueOnce({
        data: mockProducts,
        count: 2,
        error: null,
      });

      const result = await service.findAll('tenant-1', {});

      expect(result.data).toHaveLength(2);
      expect(result.total).toBe(2);
      expect(result.page).toBe(1);
      expect(mockSupabaseClient.from).toHaveBeenCalledWith('products');
      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('tenant_id', 'tenant-1');
    });

    it('should filter by category', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: [],
        count: 0,
        error: null,
      });

      await service.findAll('tenant-1', { category_id: 'cat-1' });

      expect(mockSupabaseClient.eq).toHaveBeenCalledWith('category_id', 'cat-1');
    });

    it('should throw on error', async () => {
      mockSupabaseClient.range.mockResolvedValueOnce({
        data: null,
        count: null,
        error: { message: 'DB error' },
      });

      await expect(service.findAll('tenant-1', {})).rejects.toEqual({
        message: 'DB error',
      });
    });
  });

  describe('findById', () => {
    it('should return cached product if available', async () => {
      const cached = { id: '1', name: 'Cached Product' };
      mockRedisService.get.mockResolvedValueOnce(cached);

      const result = await service.findById('tenant-1', '1');

      expect(result).toEqual(cached);
      expect(mockSupabaseClient.from).not.toHaveBeenCalled();
    });

    it('should query DB and cache on miss', async () => {
      const product = { id: '1', name: 'DB Product' };
      mockRedisService.get.mockResolvedValueOnce(null);
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: product,
        error: null,
      });

      const result = await service.findById('tenant-1', '1');

      expect(result).toEqual(product);
      expect(mockRedisService.set).toHaveBeenCalled();
    });
  });

  describe('create', () => {
    it('should insert product and invalidate cache', async () => {
      const newProduct = { id: '1', name: 'New Product', price: 15000 };
      mockSupabaseClient.single.mockResolvedValueOnce({
        data: newProduct,
        error: null,
      });

      const result = await service.create('tenant-1', {
        name: 'New Product',
        base_price: 15000,
        category_id: 'cat-1',
      });

      expect(result).toEqual(newProduct);
      expect(mockSupabaseClient.from).toHaveBeenCalledWith('products');
      expect(mockRedisService.delPattern).toHaveBeenCalled();
    });
  });
});
