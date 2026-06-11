import { Controller, Get, Query } from '@nestjs/common';
import { ReportService } from './report.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('reports')
export class ReportController {
  constructor(private reportService: ReportService) {}

  @Get('revenue')
  getRevenueReport(
    @CurrentUser() user: AuthenticatedUser,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('groupBy') groupBy?: 'day' | 'week' | 'month',
  ) {
    return this.reportService.getRevenueReport(
      user.tenantId!,
      startDate,
      endDate,
      groupBy || 'day',
    );
  }

  @Get('products')
  getProductReport(
    @CurrentUser() user: AuthenticatedUser,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
    @Query('limit') limit?: string,
  ) {
    return this.reportService.getProductReport(
      user.tenantId!,
      startDate,
      endDate,
      limit ? parseInt(limit) : 50,
    );
  }

  @Get('inventory')
  getInventoryReport(@CurrentUser() user: AuthenticatedUser) {
    return this.reportService.getInventoryReport(user.tenantId!);
  }

  @Get('customers')
  getCustomerReport(
    @CurrentUser() user: AuthenticatedUser,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.reportService.getCustomerReport(user.tenantId!, startDate, endDate);
  }

  @Get('export')
  exportReport(
    @CurrentUser() user: AuthenticatedUser,
    @Query('type') reportType: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.reportService.exportReport(user.tenantId!, reportType, startDate, endDate);
  }
}
