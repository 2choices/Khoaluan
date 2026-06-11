import { Test, TestingModule } from '@nestjs/testing';
import { AiGatewayService } from '../ai/ai-gateway.service';
import { ConfigService } from '@nestjs/config';

describe('AiGatewayService', () => {
  let service: AiGatewayService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiGatewayService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockReturnValue('http://localhost:8000'),
          },
        },
      ],
    }).compile();

    service = module.get<AiGatewayService>(AiGatewayService);
  });

  describe('proxy', () => {
    it('should return error when AI service is unreachable', async () => {
      // fetch will fail since no server is running
      const result = await service.proxy('/recommendations/products', 'POST', {
        tenant_id: 'test',
      });

      expect(result).toHaveProperty('error');
      expect(result.error).toContain('AI Service unavailable');
    });
  });

  describe('getRecommendations', () => {
    it('should call proxy with correct params', async () => {
      const spy = jest.spyOn(service, 'proxy').mockResolvedValue({
        product_ids: ['p1', 'p2'],
        scores: [0.9, 0.8],
        method: 'user_based_cf',
      });

      const result = await service.getRecommendations('tenant-1', 'customer-1');

      expect(spy).toHaveBeenCalledWith('/recommendations/products', 'POST', {
        tenant_id: 'tenant-1',
        customer_id: 'customer-1',
        product_id: undefined,
        limit: 10,
      });
      expect(result.product_ids).toHaveLength(2);
    });
  });

  describe('getCustomerSegments', () => {
    it('should call proxy with correct params', async () => {
      const spy = jest.spyOn(service, 'proxy').mockResolvedValue([
        { customer_id: 'c1', segment: 0, segment_name: 'Champions' },
      ]);

      const result = await service.getCustomerSegments('tenant-1', 4);

      expect(spy).toHaveBeenCalledWith('/analytics/segments', 'POST', {
        tenant_id: 'tenant-1',
        n_clusters: 4,
      });
      expect(result).toHaveLength(1);
    });
  });
});
