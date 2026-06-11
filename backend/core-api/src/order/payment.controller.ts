import { Controller, Post, Body, Headers } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import { Public } from '../auth/decorators/public.decorator';

@Controller('payments')
export class PaymentController {
  constructor(private paymentService: PaymentService) {}

  @Post()
  createPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: any,
  ) {
    return this.paymentService.createPayment(user.tenantId!, body);
  }

  @Post('payos')
  createPayOSPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Body('orderId') orderId: string,
  ) {
    return this.paymentService.createPayOSPayment(user.tenantId!, orderId);
  }

  @Post('payos/confirm-order')
  confirmPayOSOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Body('orderId') orderId: string,
  ) {
    return this.paymentService.confirmPayOSOrder(user.tenantId!, orderId);
  }

  /** PayOS webhook - public endpoint (no JWT required) */
  @Post('payos/webhook')
@Public()
handlePayOSWebhook(
  @Body() payload: any,
  @Headers('x-payos-signature') headerSignature: string,
) {
  const signature = headerSignature || payload?.signature || '';
  return this.paymentService.handlePayOSWebhook(payload, signature);
}
}