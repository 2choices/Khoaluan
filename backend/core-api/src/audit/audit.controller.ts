import { Controller, Get, Query } from '@nestjs/common';
import { AuditService } from './audit.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('audit')
export class AuditController {
  constructor(private auditService: AuditService) {}

  @Get('logs')
  getLogs(
    @CurrentUser() user: AuthenticatedUser,
    @Query('userId') userId?: string,
    @Query('action') action?: string,
    @Query('entityType') entityType?: string,
    @Query('entityId') entityId?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.auditService.getLogs(user.tenantId!, {
      userId,
      action,
      entityType,
      entityId,
      startDate,
      endDate,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 50,
    });
  }

  @Get('actions')
  getActionTypes(@CurrentUser() user: AuthenticatedUser) {
    return this.auditService.getActionTypes(user.tenantId!);
  }
}
