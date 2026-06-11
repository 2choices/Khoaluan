import { Resolver, Query, Mutation, Args, ID } from '@nestjs/graphql';
import { ShiftService } from './shift.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Shift,
  ShiftReport,
  OpenShiftInput,
  CloseShiftInput,
} from './dto/shift.types';

@Resolver(() => Shift)
export class ShiftResolver {
  constructor(private shiftService: ShiftService) {}

  @Query(() => Shift, { nullable: true })
  async currentShift(@CurrentUser() user: AuthenticatedUser) {
    return this.shiftService.getCurrentShift(user.tenantId!, user.id);
  }

  @Query(() => ShiftReport)
  async shiftReport(
    @CurrentUser() user: AuthenticatedUser,
    @Args('shiftId', { type: () => ID }) shiftId: string,
  ) {
    return this.shiftService.getShiftReport(user.tenantId!, shiftId);
  }

  @Query(() => [Shift])
  async shiftHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Args('branchId', { type: () => ID, nullable: true }) branchId?: string,
  ) {
    const result = await this.shiftService.getShiftHistory(user.tenantId!, branchId);
    return result.data;
  }

  @Mutation(() => Shift)
  async openShift(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: OpenShiftInput,
  ) {
    return this.shiftService.openShift(user.tenantId!, user.id, input);
  }

  @Mutation(() => Shift)
  async closeShift(
    @CurrentUser() user: AuthenticatedUser,
    @Args('shiftId', { type: () => ID }) shiftId: string,
    @Args('input') input: CloseShiftInput,
  ) {
    return this.shiftService.closeShift(user.tenantId!, user.id, shiftId, input);
  }
}
