import { Resolver, Query, Mutation, Args, ID, Int } from '@nestjs/graphql';
import { InventoryService } from './inventory.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';
import {
  Inventory,
  Warehouse,
  StockMovement,
  StockBatch,
  LowStockAlert,
  CreateWarehouseInput,
  CreateStockMovementInput,
  StocktakeInput,
  CreateBatchInput,
  InventoryFilterInput,
} from './dto/inventory.types';

@Resolver()
export class InventoryResolver {
  constructor(private inventoryService: InventoryService) {}

  // ---- Warehouses ----

  @Query(() => [Warehouse])
  async warehouses(@CurrentUser() user: AuthenticatedUser) {
    return this.inventoryService.getWarehouses(user.tenantId!);
  }

  @Mutation(() => Warehouse)
  async createWarehouse(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateWarehouseInput,
  ) {
    return this.inventoryService.createWarehouse(user.tenantId!, input);
  }

  // ---- Inventory ----

  @Query(() => [Inventory])
  async inventory(
    @CurrentUser() user: AuthenticatedUser,
    @Args('filter', { nullable: true }) filter?: InventoryFilterInput,
  ) {
    const result = await this.inventoryService.getInventory(user.tenantId!, filter);
    return result.data;
  }

  @Query(() => [Inventory])
  async productStock(
    @CurrentUser() user: AuthenticatedUser,
    @Args('productId', { type: () => ID }) productId: string,
  ) {
    return this.inventoryService.getProductStock(user.tenantId!, productId);
  }

  // ---- Stock Movements ----

  @Mutation(() => StockMovement)
  async createStockMovement(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateStockMovementInput,
  ) {
    return this.inventoryService.createMovement(user.tenantId!, user.id, input);
  }

  // ---- Stocktake ----

  @Mutation(() => Boolean)
  async stocktake(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: StocktakeInput,
  ) {
    const result = await this.inventoryService.stocktake(user.tenantId!, user.id, input);
    return result.adjusted;
  }

  // ---- Batches ----

  @Query(() => [StockBatch])
  async stockBatches(
    @CurrentUser() user: AuthenticatedUser,
    @Args('productId', { type: () => ID }) productId: string,
    @Args('warehouseId', { type: () => ID, nullable: true }) warehouseId?: string,
  ) {
    return this.inventoryService.getBatches(user.tenantId!, productId, warehouseId);
  }

  @Mutation(() => StockBatch)
  async createStockBatch(
    @CurrentUser() user: AuthenticatedUser,
    @Args('input') input: CreateBatchInput,
  ) {
    return this.inventoryService.createBatch(user.tenantId!, input);
  }

  // ---- Alerts ----

  @Query(() => [LowStockAlert])
  async lowStockAlerts(@CurrentUser() user: AuthenticatedUser) {
    return this.inventoryService.getLowStockAlerts(user.tenantId!);
  }
}
