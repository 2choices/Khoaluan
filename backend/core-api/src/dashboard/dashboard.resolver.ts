import { Resolver, Query, Args, Int, ID } from '@nestjs/graphql';
import { DashboardService } from './dashboard.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  DashboardStats,
  TopProduct,
  TopCustomer,
  RevenueByPeriod,
} from './dto/dashboard.types';

@Resolver()
export class DashboardResolver {
  constructor(private dashboardService: DashboardService) {}

  @Query(() => DashboardStats)
  async dashboardStats(
    @CurrentUser() user: AuthenticatedUser,
    @Args('branchId', { type: () => ID, nullable: true }) branchId?: string,
  ) {
    return this.dashboardService.getStats(user.tenantId!, branchId);
  }

  @Query(() => [TopProduct])
  async topProducts(
    @CurrentUser() user: AuthenticatedUser,
    @Args('days', { type: () => Int, nullable: true, defaultValue: 30 }) days?: number,
    @Args('limit', { type: () => Int, nullable: true, defaultValue: 10 }) limit?: number,
  ) {
    return this.dashboardService.getTopProducts(user.tenantId!, days, limit);
  }

  @Query(() => [TopCustomer])
  async topCustomers(
    @CurrentUser() user: AuthenticatedUser,
    @Args('days', { type: () => Int, nullable: true, defaultValue: 30 }) days?: number,
    @Args('limit', { type: () => Int, nullable: true, defaultValue: 10 }) limit?: number,
  ) {
    return this.dashboardService.getTopCustomers(user.tenantId!, days, limit);
  }

  @Query(() => [RevenueByPeriod])
  async revenueByDay(
    @CurrentUser() user: AuthenticatedUser,
    @Args('days', { type: () => Int, nullable: true, defaultValue: 30 }) days?: number,
  ) {
    return this.dashboardService.getRevenueByDay(user.tenantId!, days);
  }
}
