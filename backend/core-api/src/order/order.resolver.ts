import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { OrderService } from './order.service';
import { PaymentService } from './payment.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Order,
  Payment,
  CreateOrderInput,
  CreatePaymentInput,
  OrderFilterInput,
  OrderStatus,
} from './dto/order.types';

@Resolver(() => Order)
export class OrderResolver {
  constructor(
    private orderService: OrderService,
    private paymentService: PaymentService,
  ) {}

  @Query(() => [Order])
  async orders(
    @CurrentUser() user: AuthenticatedUser,
    @Args('filter', { nullable: true }) filter?: OrderFilterInput,
  ) {
    const result = await this.orderService.findAll(user.tenantId!, filter);
    return result.data;
  }

  @Query(() => Order)
  async order(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.orderService.findById(user.tenantId!, id);
  }

  @Query(() => [Order])
  async holdOrders(
    @CurrentUser() user: AuthenticatedUser,
    @Args('branchId', { type: () => ID }) branchId: string,
  ) {
    return this.orderService.getHoldOrders(user.tenantId!, branchId);
  }

  @Mutation(() => Order)
  async createOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateOrderInput,
  ) {
    return this.orderService.create(user.tenantId!, user.id, input);
  }

  @Mutation(() => Order)
  async holdOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateOrderInput,
  ) {
    return this.orderService.holdOrder(user.tenantId!, user.id, input);
  }

  @Mutation(() => Order)
  async updateOrderStatus(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('status', { type: () => OrderStatus }) status: OrderStatus,
  ) {
    return this.orderService.updateStatus(user.tenantId!, id, status);
  }

  @Mutation(() => Order)
  async cancelOrder(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.orderService.cancelOrder(user.tenantId!, id);
  }

  @Mutation(() => Payment)
  async createPayment(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreatePaymentInput,
  ) {
    return this.paymentService.createPayment(user.tenantId!, input);
  }
}
