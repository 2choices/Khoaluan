import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('inventory')
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  // ---- Warehouses ----

  @Get('warehouses')
  getWarehouses(@CurrentUser() user: AuthenticatedUser) {
    return this.inventoryService.getWarehouses(user.tenantId!);
  }

  @Post('warehouses')
  createWarehouse(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.inventoryService.createWarehouse(user.tenantId!, body);
  }

  @Put('warehouses/:id')
  updateWarehouse(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.inventoryService.updateWarehouse(user.tenantId!, id, body);
  }

  // ---- Stock ----

  @Get()
  getInventory(
    @CurrentUser() user: AuthenticatedUser,
    @Query('warehouse_id') warehouseId?: string,
    @Query('product_id') productId?: string,
    @Query('low_stock') lowStock?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.getInventory(user.tenantId!, {
      warehouse_id: warehouseId,
      product_id: productId,
      low_stock_only: lowStock === 'true',
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 50,
    });
  }

  @Get('product/:productId')
  getProductStock(
    @CurrentUser() user: AuthenticatedUser,
    @Param('productId') productId: string,
  ) {
    return this.inventoryService.getProductStock(user.tenantId!, productId);
  }

  // ---- Movements ----

  @Post('movements')
  createMovement(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.inventoryService.createMovement(user.tenantId!, user.id, body);
  }

  @Get('movements')
  getMovements(
    @CurrentUser() user: AuthenticatedUser,
    @Query('warehouse_id') warehouseId?: string,
    @Query('product_id') productId?: string,
    @Query('type') type?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.getMovements(user.tenantId!, {
      warehouse_id: warehouseId,
      product_id: productId,
      movement_type: type,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 50,
    });
  }

  // ---- Stocktake ----

  @Post('stocktake')
  stocktake(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.inventoryService.stocktake(user.tenantId!, user.id, body);
  }

  // ---- Batches ----

  @Get('batches/:productId')
  getBatches(
    @CurrentUser() user: AuthenticatedUser,
    @Param('productId') productId: string,
    @Query('warehouse_id') warehouseId?: string,
  ) {
    return this.inventoryService.getBatches(user.tenantId!, productId, warehouseId);
  }

  @Post('batches')
  createBatch(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.inventoryService.createBatch(user.tenantId!, body);
  }

  // ---- Alerts ----

  @Get('alerts/low-stock')
  getLowStockAlerts(@CurrentUser() user: AuthenticatedUser) {
    return this.inventoryService.getLowStockAlerts(user.tenantId!);
  }
}
