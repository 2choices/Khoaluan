import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { GraphQLModule } from '@nestjs/graphql';
import { ApolloDriver, ApolloDriverConfig } from '@nestjs/apollo';
import { BullModule } from '@nestjs/bull';
import { AuthModule } from './auth/auth.module';
import { TenantModule } from './tenant/tenant.module';
import { HealthModule } from './health/health.module';
import { SupabaseModule } from './supabase/supabase.module';
import { RedisModule } from './redis/redis.module';
import { ProductModule } from './product/product.module';
import { MediaModule } from './media/media.module';
import { InventoryModule } from './inventory/inventory.module';
import { OrderModule } from './order/order.module';
import { ShiftModule } from './shift/shift.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { CustomerModule } from './customer/customer.module';
import { EmployeeModule } from './employee/employee.module';
import { CatalogModule } from './catalog/catalog.module';
import { ShippingModule } from './shipping/shipping.module';
import { NotificationModule } from './notification/notification.module';
import { VoucherModule } from './voucher/voucher.module';
import { CashBookModule } from './cashbook/cashbook.module';
import { ReportModule } from './report/report.module';
import { AiModule } from './ai/ai.module';
import { AuditModule } from './audit/audit.module';
import { EmailModule } from './email/email.module';
import configuration from './config/configuration';
import { getRedisOptions } from './config/redis-options';

const baseRedisOptions = getRedisOptions();
const bullRedisOptions = baseRedisOptions
  ? {
      ...baseRedisOptions,
      // Bull should queue commands while reconnecting to avoid uncaught stream write errors.
      enableOfflineQueue: true,
      // Bull recommends null so blocking commands are not rejected early.
      maxRetriesPerRequest: null,
      // Let Bull establish connection immediately.
      lazyConnect: false,
    }
  : {
      host: '127.0.0.1',
      port: 6379,
      lazyConnect: true,
      maxRetriesPerRequest: 0,
    };

@Module({
  imports: [
    // Environment config
    ConfigModule.forRoot({
      isGlobal: true,
      load: [configuration],
    }),

    // GraphQL (Apollo) - code first
    GraphQLModule.forRoot<ApolloDriverConfig>({
      driver: ApolloDriver,
      autoSchemaFile: true,
      sortSchema: true,
      playground: process.env.NODE_ENV !== 'production',
      context: ({ req }: { req: any }) => ({ req }),
    }),

    // Bull queue (Redis-backed) — fall back to localhost noop if Redis disabled
    BullModule.forRoot({
      redis: bullRedisOptions,
    }),

    // Core modules
    SupabaseModule,
    AuthModule,
    TenantModule,
    RedisModule,
    HealthModule,
    ProductModule,
    MediaModule,
    InventoryModule,
    OrderModule,
    ShiftModule,
    DashboardModule,
    CustomerModule,
    EmployeeModule,
    CatalogModule,
    ShippingModule,
    NotificationModule,
    VoucherModule,
    CashBookModule,
    ReportModule,
    AiModule,
    AuditModule,
    EmailModule,
  ],
})
export class AppModule {}
