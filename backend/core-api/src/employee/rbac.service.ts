import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { RedisService } from '../redis/redis.service';

@Injectable()
export class RbacService {
  constructor(
    private supabase: SupabaseService,
    private redis: RedisService,
  ) {}

  private get db() {
    return this.supabase.getAdminClient();
  }

  /** Check if user has a specific permission */
  async hasPermission(
    tenantId: string,
    userId: string,
    permission: string,
    branchId?: string,
  ): Promise<boolean> {
    const cacheKey = `rbac:${tenantId}:${userId}`;
    let permissions = await this.redis.get<string[]>(cacheKey);

    if (!permissions) {
      // Load user roles and permissions
      const { data: userRoles } = await this.db
        .from('user_roles')
        .select('role_id, branch_id')
        .eq('user_id', userId);

      if (!userRoles || userRoles.length === 0) return false;

      // Filter by branch if specified
      const roleIds = userRoles
        .filter((ur: any) => !branchId || !ur.branch_id || ur.branch_id === branchId)
        .map((ur: any) => ur.role_id);

      if (roleIds.length === 0) return false;

      // Get permissions for these roles
      const { data: rolePerms } = await this.db
        .from('role_permissions')
        .select('permission_id, permissions(code)')
        .in('role_id', roleIds);

      permissions = (rolePerms || []).map((rp: any) => rp.permissions?.code).filter(Boolean);
      await this.redis.set(cacheKey, permissions, 600);
    }

    return permissions.includes(permission);
  }

  /** Get all permissions for a user */
  async getUserPermissions(tenantId: string, userId: string): Promise<string[]> {
    const cacheKey = `rbac:${tenantId}:${userId}`;
    const cached = await this.redis.get<string[]>(cacheKey);
    if (cached) return cached;

    const { data: userRoles } = await this.db
      .from('user_roles')
      .select('role_id')
      .eq('user_id', userId);

    if (!userRoles || userRoles.length === 0) return [];

    const roleIds = userRoles.map((ur: any) => ur.role_id);

    const { data: rolePerms } = await this.db
      .from('role_permissions')
      .select('permissions(code)')
      .in('role_id', roleIds);

    const permissions = (rolePerms || [])
      .map((rp: any) => rp.permissions?.code)
      .filter(Boolean);

    await this.redis.set(cacheKey, permissions, 600);
    return permissions;
  }

  /** Get all roles for tenant */
  async getRoles(tenantId: string) {
    const { data, error } = await this.db
      .from('roles')
      .select('*, role_permissions(permission_id, permissions(code, name, module))')
      .eq('tenant_id', tenantId)
      .order('name');

    if (error) throw error;
    return data || [];
  }

  /** Assign role to user */
  async assignRole(userId: string, roleId: string, branchId?: string) {
    const { data, error } = await this.db
      .from('user_roles')
      .insert({ user_id: userId, role_id: roleId, branch_id: branchId })
      .select()
      .single();

    if (error) throw error;
    await this.redis.delPattern(`rbac:*:${userId}`);
    return data;
  }

  /** Remove role from user */
  async removeRole(userId: string, roleId: string) {
    await this.db
      .from('user_roles')
      .delete()
      .eq('user_id', userId)
      .eq('role_id', roleId);

    await this.redis.delPattern(`rbac:*:${userId}`);
    return true;
  }

  /** Clear permission cache for user */
  async clearCache(userId: string) {
    await this.redis.delPattern(`rbac:*:${userId}`);
  }
}
