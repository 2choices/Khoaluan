import { Injectable, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';
import {
  CreateCustomerInput,
  UpdateCustomerInput,
  CustomerFilterInput,
  CreateCustomerGroupInput,
} from './dto/customer.types';

@Injectable()
export class CustomerService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  async findAll(tenantId: string, filter: CustomerFilterInput = {}) {
    const page = filter.page || 1;
    const limit = filter.limit || 20;
    const offset = (page - 1) * limit;

    let query = this.db
      .from('customers')
      .select('*, group:customer_groups(*)', { count: 'exact' })
      .eq('tenant_id', tenantId);

    if (filter.search) {
      query = query.or(`full_name.ilike.%${filter.search}%,phone.ilike.%${filter.search}%,email.ilike.%${filter.search}%`);
    }
    if (filter.group_id) query = query.eq('group_id', filter.group_id);
    if (filter.is_active !== undefined) query = query.eq('is_active', filter.is_active);
    if (filter.loyalty_tier) query = query.eq('loyalty_tier', filter.loyalty_tier);

    query = query.order('created_at', { ascending: false }).range(offset, offset + limit - 1);

    const { data, count, error } = await query;
    if (error) throw error;
    return { data: data || [], total: count || 0, page, limit };
  }

  async findById(tenantId: string, id: string) {
    const { data, error } = await this.db
      .from('customers')
      .select('*, group:customer_groups(*)')
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .single();

    if (error || !data) throw new NotFoundException('Customer not found');
    return data;
  }

  async findByPhone(tenantId: string, phone: string) {
    const { data } = await this.db
      .from('customers')
      .select('*')
      .eq('tenant_id', tenantId)
      .eq('phone', phone)
      .maybeSingle();

    return data;
  }

  async create(tenantId: string, input: CreateCustomerInput) {
    const { data, error } = await this.db
      .from('customers')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async update(tenantId: string, id: string, input: UpdateCustomerInput) {
    const { data, error } = await this.db
      .from('customers')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Customer not found');
    return data;
  }

  async remove(tenantId: string, id: string) {
    const { error } = await this.db
      .from('customers')
      .delete()
      .eq('tenant_id', tenantId)
      .eq('id', id);

    if (error) throw error;
    return true;
  }

  // ---- Customer Addresses ----

  /**
   * Lấy customer record cho user hiện tại. Nếu chưa tồn tại thì tự tạo
   * (auto-provision khi customer app login lần đầu).
   */
  private async getCustomerIdByUserId(userId: string, tenantId: string): Promise<string> {
    const { data } = await this.db
      .from('customers')
      .select('id')
      .eq('user_id', userId)
      .eq('tenant_id', tenantId)
      .maybeSingle();

    if (data) return data.id;

    // Auto-create skeleton profile
    const { data: created, error } = await this.db
      .from('customers')
      .insert({
        tenant_id: tenantId,
        user_id: userId,
        full_name: 'Khách hàng',
        is_active: true,
      })
      .select('id')
      .single();
    if (error || !created) throw new NotFoundException('Customer profile not found');
    return created.id;
  }

  async getMyProfile(userId: string, tenantId: string) {
    const id = await this.getCustomerIdByUserId(userId, tenantId);
    return this.findById(tenantId, id);
  }

  async updateMyProfile(
    userId: string,
    tenantId: string,
    input: Record<string, unknown>,
  ) {
    const id = await this.getCustomerIdByUserId(userId, tenantId);
    const allowed: Record<string, unknown> = {};
    for (const k of ['full_name', 'phone', 'email', 'gender', 'birthday', 'avatar_url']) {
      if (input[k] !== undefined) allowed[k] = input[k];
    }
    return this.update(tenantId, id, allowed as any);
  }

  async getMyAddresses(userId: string, tenantId: string) {
    const customerId = await this.getCustomerIdByUserId(userId, tenantId);
    const { data, error } = await this.db
      .from('customer_addresses')
      .select('*')
      .eq('customer_id', customerId)
      .order('is_default', { ascending: false })
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  }

  async addAddress(userId: string, tenantId: string, input: Record<string, unknown>) {
    const customerId = await this.getCustomerIdByUserId(userId, tenantId);

    // Nếu là địa chỉ đầu tiên thì tự động đặt làm mặc định
    const { count } = await this.db
      .from('customer_addresses')
      .select('*', { count: 'exact', head: true })
      .eq('customer_id', customerId);

    const isDefault = (count === 0) || (input.is_default === true);

    const { data, error } = await this.db
      .from('customer_addresses')
      .insert({ ...input, customer_id: customerId, tenant_id: tenantId, is_default: isDefault })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateAddress(userId: string, tenantId: string, addressId: string, input: Record<string, unknown>) {
    const customerId = await this.getCustomerIdByUserId(userId, tenantId);
    const { data, error } = await this.db
      .from('customer_addresses')
      .update(input)
      .eq('id', addressId)
      .eq('customer_id', customerId)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Address not found');
    return data;
  }

  async removeAddress(userId: string, tenantId: string, addressId: string) {
    const customerId = await this.getCustomerIdByUserId(userId, tenantId);
    const { error } = await this.db
      .from('customer_addresses')
      .delete()
      .eq('id', addressId)
      .eq('customer_id', customerId);

    if (error) throw error;
    return true;
  }

  async setDefaultAddress(userId: string, tenantId: string, addressId: string) {
    const customerId = await this.getCustomerIdByUserId(userId, tenantId);
    const { data, error } = await this.db
      .from('customer_addresses')
      .update({ is_default: true })
      .eq('id', addressId)
      .eq('customer_id', customerId)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Address not found');
    return data;
  }

  // ---- Customer Groups ----

  async getGroups(tenantId: string) {
    const { data, error } = await this.db
      .from('customer_groups')
      .select('*')
      .eq('tenant_id', tenantId)
      .order('name');

    if (error) throw error;
    return data || [];
  }

  async createGroup(tenantId: string, input: CreateCustomerGroupInput) {
    const { data, error } = await this.db
      .from('customer_groups')
      .insert({ ...input, tenant_id: tenantId })
      .select()
      .single();

    if (error) throw error;
    return data;
  }

  async updateGroup(tenantId: string, id: string, input: Partial<CreateCustomerGroupInput>) {
    const { data, error } = await this.db
      .from('customer_groups')
      .update(input)
      .eq('tenant_id', tenantId)
      .eq('id', id)
      .select()
      .single();

    if (error || !data) throw new NotFoundException('Group not found');
    return data;
  }
}
