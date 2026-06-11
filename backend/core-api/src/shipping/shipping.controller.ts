import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { ShippingService } from './shipping.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import { Public } from '../auth/decorators/public.decorator';

@Controller('shipping')
export class ShippingController {
  constructor(private shippingService: ShippingService) {}

  @Post('fee')
  calculateFee(@Body() body: any) {
    return this.shippingService.calculateFee(body);
  }

  @Post('leadtime')
  getLeadTime(@Body() body: any) {
    return this.shippingService.getLeadTime(body);
  }

  @Post('orders')
  createOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: any,
  ) {
    return this.shippingService.createShippingOrder(
      user.tenantId!,
      body.order_id,
      body,
    );
  }

  @Get('track/:orderCode')
  trackOrder(@Param('orderCode') orderCode: string) {
    return this.shippingService.trackOrder(orderCode);
  }

  // ---- Address data (public) ----

  @Get('provinces')
  @Public()
  getProvinces() {
    return this.shippingService.getProvinces();
  }

  @Get('districts/:provinceId')
  @Public()
  getDistricts(@Param('provinceId') provinceId: string) {
    return this.shippingService.getDistricts(parseInt(provinceId));
  }

  @Get('wards/:districtId')
  @Public()
  getWards(@Param('districtId') districtId: string) {
    return this.shippingService.getWards(parseInt(districtId));
  }
}
