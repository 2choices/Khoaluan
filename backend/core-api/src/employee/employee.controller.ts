import {
  Controller,
  Get,
  Post,
  Put,
  Param,
  Body,
  Query,
} from '@nestjs/common';
import { EmployeeService } from './employee.service';
import { RbacService } from './rbac.service';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AuthenticatedUser } from '../auth/strategies/supabase-jwt.strategy';

@Controller('employees')
export class EmployeeController {
  constructor(
    private employeeService: EmployeeService,
    private rbacService: RbacService,
  ) {}

  @Get()
  findAll(
    @CurrentUser() user: AuthenticatedUser,
    @Query('branch_id') branchId?: string,
    @Query('page') page?: string,
  ) {
    return this.employeeService.findAll(
      user.tenantId!,
      branchId,
      page ? parseInt(page) : 1,
    );
  }

  @Get('roles')
  getRoles(@CurrentUser() user: AuthenticatedUser) {
    return this.rbacService.getRoles(user.tenantId!);
  }

  @Get('permissions')
  getMyPermissions(@CurrentUser() user: AuthenticatedUser) {
    return this.rbacService.getUserPermissions(user.tenantId!, user.id);
  }

  @Get(':id')
  findById(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
  ) {
    return this.employeeService.findById(user.tenantId!, id);
  }

  @Post()
  create(@CurrentUser() user: AuthenticatedUser, @Body() body: any) {
    return this.employeeService.create(user.tenantId!, body);
  }

  @Put(':id')
  update(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.employeeService.update(user.tenantId!, id, body);
  }

  // ---- Role assignment ----

  @Post(':userId/roles')
  assignRole(
    @Param('userId') userId: string,
    @Body('roleId') roleId: string,
    @Body('branchId') branchId?: string,
  ) {
    return this.rbacService.assignRole(userId, roleId, branchId);
  }

  // ---- Attendance ----

  @Post('attendance/check-in')
  checkIn(
    @CurrentUser() user: AuthenticatedUser,
    @Body('employeeId') employeeId: string,
    @Body('branchId') branchId: string,
    @Body('location') location?: any,
  ) {
    return this.employeeService.checkIn(user.tenantId!, employeeId, branchId, location);
  }

  @Post('attendance/:id/check-out')
  checkOut(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id') id: string,
    @Body('location') location?: any,
  ) {
    return this.employeeService.checkOut(user.tenantId!, id, location);
  }

  @Get('attendance/list')
  getAttendance(
    @CurrentUser() user: AuthenticatedUser,
    @Query('employee_id') employeeId?: string,
    @Query('from') dateFrom?: string,
    @Query('to') dateTo?: string,
  ) {
    return this.employeeService.getAttendance(user.tenantId!, employeeId, dateFrom, dateTo);
  }
}
