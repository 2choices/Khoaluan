import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { AppModule } from '../app.module';

/**
 * E2E test setup helper.
 * Sử dụng cho integration tests khi cần test full HTTP request flow.
 *
 * Lưu ý: Cần mock SupabaseService và RedisService trước khi chạy.
 * Trong CI, set env: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
 */
export async function createTestApp(): Promise<INestApplication> {
  const moduleFixture: TestingModule = await Test.createTestingModule({
    imports: [AppModule],
  }).compile();

  const app = moduleFixture.createNestApplication();
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, transform: true }),
  );

  await app.init();
  return app;
}

/**
 * Mock JWT token for testing authenticated endpoints.
 */
export function getMockAuthHeaders(tenantId = 'test-tenant', userId = 'test-user') {
  return {
    Authorization: 'Bearer mock-jwt-token',
    'x-tenant-id': tenantId,
  };
}
