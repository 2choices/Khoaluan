import { Injectable, NestMiddleware, UnauthorizedException } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { TenantService } from './tenant.service';

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(private tenantService: TenantService) {}

  use(req: Request, _res: Response, next: NextFunction) {
    // Tenant ID comes from JWT app_metadata (set during Supabase signup)
    const user = (req as any).user;
    if (user?.tenantId) {
      this.tenantService.setTenantId(user.tenantId);
    }

    // Also allow explicit header override for service-to-service calls
    const headerTenantId = req.headers['x-tenant-id'] as string;
    if (headerTenantId && !user) {
      this.tenantService.setTenantId(headerTenantId);
    }

    next();
  }
}
