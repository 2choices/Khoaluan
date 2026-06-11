import { Module } from '@nestjs/common';
import { EmployeeService } from './employee.service';
import { EmployeeController } from './employee.controller';
import { RbacService } from './rbac.service';
import { RbacGuard } from './rbac.guard';

@Module({
  providers: [EmployeeService, RbacService, RbacGuard],
  controllers: [EmployeeController],
  exports: [EmployeeService, RbacService, RbacGuard],
})
export class EmployeeModule {}
