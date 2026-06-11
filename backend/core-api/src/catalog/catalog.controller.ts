import { Controller, Get, Param, Query, Headers, Req } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { Public } from '../auth/decorators/public.decorator';
import { Request } from 'express';

const DEFAULT_TENANT_ID = 'a0000000-0000-0000-0000-000000000001';

/** Public endpoints for Customer App (no JWT required, tenant from header or JWT) */
@Controller('catalog')
export class CatalogController {
  constructor(private catalogService: CatalogService) {}

  /** Resolve tenantId: header > JWT app_metadata > default demo tenant */
  private resolveTenantId(headerTenantId: string | undefined, req: Request): string {
    if (headerTenantId) return headerTenantId;
    const user = (req as any).user;
    if (user?.tenantId) return user.tenantId;
    return DEFAULT_TENANT_ID;
  }

  @Get('products')
  @Public()
  getProducts(
    @Headers('x-tenant-id') tenantId: string,
    @Req() req: Request,
    @Query('search') search?: string,
    @Query('category_id') categoryId?: string,
    @Query('featured') featured?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const tid = this.resolveTenantId(tenantId, req);
    return this.catalogService.getProducts(tid, {
      search,
      categoryId,
      featured: featured === 'true',
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Get('products/:id')
  @Public()
  getProductDetail(
    @Headers('x-tenant-id') tenantId: string,
    @Req() req: Request,
    @Param('id') id: string,
  ) {
    const tid = this.resolveTenantId(tenantId, req);
    return this.catalogService.getProductDetail(tid, id);
  }

  @Get('categories')
  @Public()
  getCategories(
    @Headers('x-tenant-id') tenantId: string,
    @Req() req: Request,
  ) {
    const tid = this.resolveTenantId(tenantId, req);
    return this.catalogService.getCategories(tid);
  }
}
