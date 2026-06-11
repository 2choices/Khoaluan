import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class EmployeeService {
  constructor(private supabase: SupabaseService) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async findAll(tenantId: string, branchId?: string, page = 1, limit = 20) {
    const offset = (page - 1) * limit;

    let query = this.db
      .from('employees')
      .select('*, user:users(id, email, full_name, phone, avatar_url)', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (branchId) query = query.eq('branch_id', branchId);

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  async findById(tenantId: string, id: string) {
    const { data, error } = await this.db
      .from('employees')
      .select('*, user:users(id, email, full_name, phone, avatar_url)')
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error || !data) throw new NotFoundException('Employee not found');
    return data;
  }

  async create(tenantId: string, input: any) {
    const { data, error } = await this.db
      .from('employees')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async update(tenantId: string, id: string, input: any) {
    const { data, error } = await this.db
      .from('employees')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Employee not found');
    return data;
  }

  // ---- Attendance ----

  async checkIn(tenantId: string, employeeId: string, branchId: string, location?: any) {
    const { data, error } = await this.db
      .from('attendance')
      .insert({
        tenant_id: tenantId,
        employee_id: employeeId,
        branch_id: branchId,
        check_in: new Date().toISOString(),
        check_in_location: location,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async checkOut(tenantId: string, attendanceId: string, location?: any) {
    const now = new Date();
    const { data: attendance } = await this.db
      .from('attendance')
      .select('check_in')
      .eq('id', attendanceId)
      .single();

    const hoursWorked = attendance
      ? (now.getTime() - new Date(attendance.check_in).getTime()) / 3600000
      : 0;

    const { data, error } = await this.db
      .from('attendance')
      .update({
        check_out: now.toISOString(),
        check_out_location: location,
        hours_worked: Math.round(hoursWorked * 100) / 100,
      })
      .eq('tenant_id', tenantId)
      .eq('id', attendanceId)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Attendance record not found');
    return data;
  }

  async getAttendance(tenantId: string, employeeId?: string, dateFrom?: string, dateTo?: string) {
    let query = this.db
      .from('attendance')
      .select('*, employee:employees(id, user:users(full_name))')
      .eq('tenant_id', tenantId);

    if (employeeId) query = query.eq('employee_id', employeeId);
    if (dateFrom) query = query.gte('check_in', dateFrom);
    if (dateTo) query = query.lte('check_in', dateTo);

    query = query.order('check_in', { ascending: false });

    const { data, error } = await query;
    if (error) throw error;
    return data || [];
  }
}
