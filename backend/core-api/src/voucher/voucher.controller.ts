import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { VoucherService } from './voucher.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import { Public } from '../auth/decorators/public.decorator';

@Controller('vouchers')
export class VoucherController {
  constructor(private voucherService: VoucherService) {}

  @Post()
  create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: any,
  ) {
    return this.voucherService.create(user.tenantId!, body);
  }

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('active') active?: string,
  ) {
    return this.voucherService.findAll(
      user.tenantId!,
      page ? parseInt(page) : 1,
      limit ? parseInt(limit) : 20,
      active !== undefined ? active === 'true' : undefined,
    );
  }

  @Get(':id')
  findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.voucherService.findById(user.tenantId!, id);
  }

  @Post('validate')
  validateCode(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { code: string; orderAmount: number },
  ) {
    return this.voucherService.validateCode(
      user.tenantId!,
      body.code,
      body.orderAmount,
      user.id,
    );
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.voucherService.update(user.tenantId!, id, body);
  }

  @Patch(':id/toggle')
  toggleActive(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.voucherService.toggleActive(user.tenantId!, id);
  }

  @Delete(':id')
  delete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.voucherService.delete(user.tenantId!, id);
  }
}
