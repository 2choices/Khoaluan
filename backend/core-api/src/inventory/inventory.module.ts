import { Module } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { InventoryResolver } from './inventory.resolver';
import { InventoryController } from './inventory.controller';

@Module({
  providers: [InventoryService, InventoryResolver],
  controllers: [InventoryController],
  exports: [InventoryService],
})
export class InventoryModule {}
