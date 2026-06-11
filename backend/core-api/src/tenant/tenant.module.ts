import { Module, Global } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { TenantMiddleware } from './tenant.middleware';
import { TenantService } from './tenant.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Global()
@Module({
  providers: [
    TenantService,
    // Apply JWT guard globally
    { provide: APP_GUARD, useClass: JwtAuthGuard },
  ],
  exports: [TenantService],
})
export class TenantModule {}
