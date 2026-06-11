import { Module } from '@nestjs/common';
import { OrderService } from './order.service';
import { OrderResolver } from './order.resolver';
import { OrderController } from './order.controller';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';

@Module({
  providers: [OrderService, OrderResolver, PaymentService],
  controllers: [OrderController, PaymentController],
  exports: [OrderService, PaymentService],
})
export class OrderModule {}
