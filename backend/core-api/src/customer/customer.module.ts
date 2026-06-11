import { Module } from '@nestjs/common';
import { CustomerService } from './customer.service';
import { CustomerResolver } from './customer.resolver';
import { CustomerController } from './customer.controller';
import { LoyaltyService } from './loyalty.service';

@Module({
  providers: [CustomerService, CustomerResolver, LoyaltyService],
  controllers: [CustomerController],
  exports: [CustomerService, LoyaltyService],
})
export class CustomerModule {}
