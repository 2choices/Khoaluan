import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { OrderService } from './order.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('orders')
export class OrderController {
  constructor(private orderService: OrderService) {}

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('status') status?: string,
    @Query('branch_id') branchId?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.orderService.findAll(user.tenantId!, {
      status: status as any,
      branch_id: branchId,
      search,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('hold/:branchId')
  getHoldOrders(
    @CurrentUser() user: AuthenticatedUser,
    @Param('branchId') branchId: string,
  ) {
    return this.orderService.getHoldOrders(user.tenantId!, branchId);
  }

  @Get(':id')
  findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.orderService.findById(user.tenantId!, id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.orderService.create(user.tenantId!, user.id, body);
  }

  @Post('hold')
  holdOrder(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.orderService.holdOrder(user.tenantId!, user.id, body);
  }

  @Put(':id/status')
  async updateStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('status') status: string,
  ) {
    try {
      // ✅ GIỮ NGUYÊN ENDPOINT - XỬ LÝ BỌC LÓT THÔNG MINH:
      // Nếu app Flutter truyền qua endpoint cập nhật chung trạng thái 'cancelled', hệ thống tự rẽ nhánh xử lý chuẩn chỉ.
      if (status && String(status).trim().toLowerCase() === 'cancelled') {
        return await this.orderService.cancelOrder(user.tenantId!, id);
      }
      return await this.orderService.updateStatus(user.tenantId!, id, status as any);
    } catch (error: any) {
      if (error instanceof NotFoundException || error instanceof BadRequestException) throw error;
      throw new BadRequestException(error.message || 'Cập nhật trạng thái không thành công');
    }
  }

  @Put(':id/cancel')
  async cancel(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    try {
      return await this.orderService.cancelOrder(user.tenantId!, id);
    } catch (error: any) {
      if (error instanceof NotFoundException || error instanceof BadRequestException) throw error;
      throw new BadRequestException(error.message || 'Hủy đơn thất bại');
    }
  }

  @Post(':id/confirm')
  async confirmOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any
  ) {
    try {
      return await this.orderService.confirmOrder(
        user.tenantId!,
        id,
        {
          paymentAmount: body?.paymentAmount || 0,
          paymentMethod: body?.paymentMethod || 'cash',
          userId: user.id,
          note: body?.note,
        }
      );
    } catch (error: any) {
      throw new BadRequestException(error.message || 'Xác nhận đơn thất bại');
    }
  }

  @Post(':id/approve')
  async approve(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    try {
      return await this.orderService.approveOrder(user.tenantId!, id);
    } catch (error: any) {
      throw new BadRequestException(error.message || 'Duyệt đơn thất bại');
    }
  }

  @Post(':id/payment')
  async recordPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: { amount: number; method: string; note?: string },
  ) {
    try {
      return await this.orderService.recordPayment(
        user.tenantId!,
        id,
        body.amount,
        body.method,
        body.note,
      );
    } catch (error: any) {
      throw new BadRequestException(error.message || 'Ghi nhận thanh toán thất bại');
    }
  }
}