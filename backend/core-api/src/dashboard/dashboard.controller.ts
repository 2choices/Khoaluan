import { Controller, Get, Query } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('dashboard')
export class DashboardController {
  constructor(private dashboardService: DashboardService) {}

  @Get('stats')
  getStats(
    @CurrentUser() user: AuthenticatedUser,
    @Query('branch_id') branchId?: string,
  ) {
    return this.dashboardService.getStats(user.tenantId!, branchId);
  }

  @Get('top-products')
  getTopProducts(
    @CurrentUser() user: AuthenticatedUser,
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    return this.dashboardService.getTopProducts(
      user.tenantId!,
      days ? parseInt(days) : 30,
      limit ? parseInt(limit) : 10,
    );
  }

  @Get('top-customers')
  getTopCustomers(
    @CurrentUser() user: AuthenticatedUser,
    @Query('days') days?: string,
    @Query('limit') limit?: string,
  ) {
    return this.dashboardService.getTopCustomers(
      user.tenantId!,
      days ? parseInt(days) : 30,
      limit ? parseInt(limit) : 10,
    );
  }

  @Get('revenue')
  getRevenue(
    @CurrentUser() user: AuthenticatedUser,
    @Query('days') days?: string,
  ) {
    return this.dashboardService.getRevenueByDay(
      user.tenantId!,
      days ? parseInt(days) : 30,
    );
  }
}
