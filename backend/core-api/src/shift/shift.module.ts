import { Module } from '@nestjs/common';
import { ShiftService } from './shift.service';
import { ShiftResolver } from './shift.resolver';
import { ShiftController } from './shift.controller';

@Module({
  providers: [ShiftService, ShiftResolver],
  controllers: [ShiftController],
  exports: [ShiftService],
})
export class ShiftModule {}
