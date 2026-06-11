import { Injectable, Scope } from '@nestjs/common';

/** Request-scoped service that holds the current tenant context */
@Injectable({ scope: Scope.REQUEST })
export class TenantService {
  private tenantId: string | null = null;

  setTenantId(tenantId: string) {
    this.tenantId = tenantId;
  }

  getTenantId(): string | null {
    return this.tenantId;
  }

  requireTenantId(): string {
    if (!this.tenantId) {
      throw new Error('Tenant context not set');
    }
    return this.tenantId;
  }
}
