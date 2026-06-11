import { Module } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { DashboardResolver } from './dashboard.resolver';
import { DashboardController } from './dashboard.controller';

@Module({
  providers: [DashboardService, DashboardResolver],
  controllers: [DashboardController],
  exports: [DashboardService],
})
export class DashboardModule {}
