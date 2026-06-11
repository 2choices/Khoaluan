import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class AiGatewayService {
  private readonly logger = new Logger(AiGatewayService.name);
  private readonly baseUrl: string;

  constructor(private config: ConfigService) {
    this.baseUrl = this.config.get<string>('AI_SERVICE_URL', 'http://localhost:8000');
  }

  /** Proxy request to AI service */
  async proxy(path: string, method: string, body?: any): Promise<any> {
    const url = `${this.baseUrl}/api/v1/ai${path}`;
    this.logger.debug(`AI Gateway → ${method} ${url}`);

    try {
      const response = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: body ? JSON.stringify(body) : undefined,
      });

      if (!response.ok) {
        const error = await response.text();
        this.logger.error(`AI Service error: ${response.status} ${error}`);
        return { error: `AI Service error: ${response.status}` };
      }

      return await response.json();
    } catch (err) {
      this.logger.error('AI Service unreachable', (err as Error).message);
      return { error: 'AI Service unavailable' };
    }
  }

  /** Gợi ý sản phẩm */
  async getRecommendations(tenantId: string, customerId?: string, productId?: string, limit = 10) {
    return this.proxy('/recommendations/products', 'POST', {
      tenant_id: tenantId,
      customer_id: customerId,
      product_id: productId,
      limit,
    });
  }

  /** Sản phẩm tương tự */
  async getSimilarProducts(tenantId: string, productId: string, limit = 10) {
    return this.proxy(`/recommendations/similar/${productId}?tenant_id=${tenantId}&limit=${limit}`, 'POST');
  }

  /** Gợi ý combo từ giỏ hàng */
  async getBasketSuggestions(tenantId: string, productIds: string[]) {
    return this.proxy('/recommendations/basket', 'POST', {
      tenant_id: tenantId,
      product_ids: productIds,
    });
  }

  /** Phân nhóm khách hàng */
  async getCustomerSegments(tenantId: string, nClusters = 4) {
    return this.proxy('/analytics/segments', 'POST', {
      tenant_id: tenantId,
      n_clusters: nClusters,
    });
  }

  /** RFM cho 1 khách hàng */
  async getCustomerRfm(tenantId: string, customerId: string) {
    return this.proxy(`/analytics/rfm/${customerId}?tenant_id=${tenantId}`, 'GET');
  }

  /** Dự đoán doanh thu */
  async getForecast(tenantId: string, periods = 30) {
    return this.proxy('/analytics/forecast', 'POST', {
      tenant_id: tenantId,
      periods,
    });
  }

  /** Phát hiện bất thường */
  async detectAnomalies(tenantId: string) {
    return this.proxy('/analytics/anomalies', 'POST', {
      tenant_id: tenantId,
    });
  }
}
