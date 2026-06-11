import { Controller, Get, Post, Patch, Delete, Body, Param, Query } from '@nestjs/common';
import { CashBookService } from './cashbook.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('cashbook')
export class CashBookController {
  constructor(private cashBookService: CashBookService) {}

  @Post()
  createEntry(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: any,
  ) {
    return this.cashBookService.createEntry(user.tenantId!, {
      ...body,
      createdBy: user.id,
    });
  }

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('branchId') branchId?: string,
    @Query('type') type?: 'income' | 'expense',
    @Query('category') category?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.cashBookService.findAll(user.tenantId!, {
      branchId,
      type,
      category,
      startDate,
      endDate,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('summary')
  getSummary(
    @CurrentUser() user: AuthenticatedUser,
    @Query('branchId') branchId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    return this.cashBookService.getSummary(user.tenantId!, branchId, startDate, endDate);
  }

  @Get('categories')
  getCategories(@CurrentUser() user: AuthenticatedUser) {
    return this.cashBookService.getCategories(user.tenantId!);
  }

  @Patch(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.cashBookService.update(user.tenantId!, id, body);
  }

  @Delete(':id')
  delete(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.cashBookService.delete(user.tenantId!, id);
  }
}
