import { Controller, Get, Post, Param, Body, Query } from '@nestjs/common';
import { ShiftService } from './shift.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('shifts')
export class ShiftController {
  constructor(private shiftService: ShiftService) {}

  @Get('current')
  getCurrentShift(@CurrentUser() user: AuthenticatedUser) {
    return this.shiftService.getCurrentShift(user.tenantId!, user.id);
  }

  @Post('open')
  openShift(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.shiftService.openShift(user.tenantId!, user.id, body);
  }

  @Post(':id/close')
  closeShift(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.shiftService.closeShift(user.tenantId!, user.id, id, body);
  }

  @Get(':id/report')
  getReport(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.shiftService.getShiftReport(user.tenantId!, id);
  }

  @Get()
  getHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Query('branch_id') branchId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.shiftService.getShiftHistory(
      user.tenantId!,
      branchId,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
    );
  }

  @Post('return')
  createReturn(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.shiftService.createReturn(user.tenantId!, user.id, body);
  }
}
