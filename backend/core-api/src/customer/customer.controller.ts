import {
  Controller,
  Get,
  Post,
  Put,
  Patch,
  Delete,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { CustomerService } from './customer.service';
import { LoyaltyService } from './loyalty.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('customers')
export class CustomerController {
  constructor(
    private customerService: CustomerService,
    private loyaltyService: LoyaltyService,
  ) {}

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('search') search?: string,
    @Query('group_id') groupId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.customerService.findAll(user.tenantId!, {
      search,
      group_id: groupId,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('phone/:phone')
  findByPhone(
    @CurrentUser() user: AuthenticatedUser,
    @Param('phone') phone: string,
  ) {
    return this.customerService.findByPhone(user.tenantId!, phone);
  }

  @Get('groups')
  getGroups(@CurrentUser() user: AuthenticatedUser) {
    return this.customerService.getGroups(user.tenantId!);
  }

  @Post('groups')
  createGroup(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.customerService.createGroup(user.tenantId!, body);
  }

  // ---- My Profile (Customer App) ----

  @Get('me')
  getMe(@CurrentUser() user: AuthenticatedUser) {
    return this.customerService.getMyProfile(user.id, user.tenantId!);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.customerService.updateMyProfile(user.id, user.tenantId!, body);
  }

  // ---- My Addresses (Customer App) — phải đặt TRƯỚC :id để tránh conflict ----

  @Get('me/addresses')
  getMyAddresses(@CurrentUser() user: AuthenticatedUser) {
    return this.customerService.getMyAddresses(user.id, user.tenantId!);
  }

  @Post('me/addresses')
  addAddress(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.customerService.addAddress(user.id, user.tenantId!, body);
  }

  @Put('me/addresses/:id')
  updateAddress(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.customerService.updateAddress(user.id, user.tenantId!, id, body);
  }

  @Delete('me/addresses/:id')
  removeAddress(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.customerService.removeAddress(user.id, user.tenantId!, id);
  }

  @Patch('me/addresses/:id/default')
  setDefaultAddress(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.customerService.setDefaultAddress(user.id, user.tenantId!, id);
  }

  @Get(':id')
  findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.customerService.findById(user.tenantId!, id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.customerService.create(user.tenantId!, body);
  }

  @Put(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.customerService.update(user.tenantId!, id, body);
  }

  @Delete(':id')
  remove(@CurrentUser() user: AuthenticatedUser, @Param('id') id: string) {
    return this.customerService.remove(user.tenantId!, id);
  }

  // ---- Loyalty ----

  @Post(':id/points')
  adjustPoints(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') customerId: string,
    @Body() body: any,
  ) {
    return this.loyaltyService.adjustPoints(user.tenantId!, {
      ...body,
      customer_id: customerId,
    });
  }

  @Get(':id/loyalty')
  getLoyaltyHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') customerId: string,
    @Query('page') page?: string,
  ) {
    return this.loyaltyService.getTransactions(
      user.tenantId!,
      customerId,
      page ? parseInt(page) : 1,
    );
  }
}
