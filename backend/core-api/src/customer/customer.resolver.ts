import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { CustomerService } from './customer.service';
import { LoyaltyService } from './loyalty.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Customer,
  CustomerGroup,
  LoyaltyTransaction,
  PaginatedCustomers,
  CreateCustomerInput,
  UpdateCustomerInput,
  CustomerFilterInput,
  CreateCustomerGroupInput,
  AdjustPointsInput,
} from './dto/customer.types';

@Resolver(() => Customer)
export class CustomerResolver {
  constructor(
    private customerService: CustomerService,
    private loyaltyService: LoyaltyService,
  ) {}

  @Query(() => PaginatedCustomers)
  async customers(
    @CurrentUser() user: AuthenticatedUser,
    @Args('filter', { nullable: true }) filter?: CustomerFilterInput,
  ) {
    return this.customerService.findAll(user.tenantId!, filter);
  }

  @Query(() => Customer)
  async customer(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.customerService.findById(user.tenantId!, id);
  }

  @Query(() => Customer, { nullable: true })
  async customerByPhone(
    @CurrentUser() user: AuthenticatedUser,
    @Args('phone') phone: string,
  ) {
    return this.customerService.findByPhone(user.tenantId!, phone);
  }

  @Mutation(() => Customer)
  async createCustomer(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateCustomerInput,
  ) {
    return this.customerService.create(user.tenantId!, input);
  }

  @Mutation(() => Customer)
  async updateCustomer(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
    @Args('input') input: UpdateCustomerInput,
  ) {
    return this.customerService.update(user.tenantId!, id, input);
  }

  @Mutation(() => Boolean)
  async deleteCustomer(
    @CurrentUser() user: AuthenticatedUser,
    @Args('id', { type: () => ID }) id: string,
  ) {
    return this.customerService.remove(user.tenantId!, id);
  }

  // ---- Groups ----

  @Query(() => [CustomerGroup])
  async customerGroups(@CurrentUser() user: AuthenticatedUser) {
    return this.customerService.getGroups(user.tenantId!);
  }

  @Mutation(() => CustomerGroup)
  async createCustomerGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateCustomerGroupInput,
  ) {
    return this.customerService.createGroup(user.tenantId!, input);
  }

  // ---- Loyalty ----

  @Mutation(() => LoyaltyTransaction)
  async adjustLoyaltyPoints(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: AdjustPointsInput,
  ) {
    return this.loyaltyService.adjustPoints(user.tenantId!, input);
  }

  @Query(() => [LoyaltyTransaction])
  async loyaltyTransactions(
    @CurrentUser() user: AuthenticatedUser,
    @Args('customerId', { type: () => ID }) customerId: string,
  ) {
    const result = await this.loyaltyService.getTransactions(user.tenantId!, customerId);
    return result.data;
  }
}
