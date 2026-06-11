import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { AiGatewayService } from './ai-gateway.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('ai')
export class AiGatewayController {
  constructor(private aiService: AiGatewayService) {}

  @Post('recommendations')
  getRecommendations(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { customerId?: string; productId?: string; limit?: number },
  ) {
    return this.aiService.getRecommendations(
      user.tenantId!,
      body.customerId,
      body.productId,
      body.limit,
    );
  }

  @Get('recommendations/similar/:productId')
  getSimilarProducts(
    @CurrentUser() user: AuthenticatedUser,
    @Param('productId') productId: string,
    @Query('limit') limit?: string,
  ) {
    return this.aiService.getSimilarProducts(
      user.tenantId!,
      productId,
      limit ? parseInt(limit) : 10,
    );
  }

  @Post('recommendations/basket')
  getBasketSuggestions(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { productIds: string[] },
  ) {
    return this.aiService.getBasketSuggestions(user.tenantId!, body.productIds);
  }

  @Get('analytics/segments')
  getCustomerSegments(
    @CurrentUser() user: AuthenticatedUser,
    @Query('clusters') clusters?: string,
  ) {
    return this.aiService.getCustomerSegments(
      user.tenantId!,
      clusters ? parseInt(clusters) : 4,
    );
  }

  @Get('analytics/rfm/:customerId')
  getCustomerRfm(
    @CurrentUser() user: AuthenticatedUser,
    @Param('customerId') customerId: string,
  ) {
    return this.aiService.getCustomerRfm(user.tenantId!, customerId);
  }

  @Get('analytics/forecast')
  getForecast(
    @CurrentUser() user: AuthenticatedUser,
    @Query('periods') periods?: string,
  ) {
    return this.aiService.getForecast(
      user.tenantId!,
      periods ? parseInt(periods) : 30,
    );
  }

  @Get('analytics/anomalies')
  detectAnomalies(@CurrentUser() user: AuthenticatedUser) {
    return this.aiService.detectAnomalies(user.tenantId!);
  }
}
