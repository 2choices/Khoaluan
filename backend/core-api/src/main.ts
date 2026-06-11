import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';

import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

function normalizeOrigins(value?: string): string[] {
  if (!value) return [];

  return value
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

function isDevelopmentOrigin(origin: string): boolean {
  return (
    /^http:\/\/localhost(:\d+)?$/.test(origin) ||
    /^http:\/\/127\.0\.0\.1(:\d+)?$/.test(origin) ||
    /^http:\/\/0\.0\.0\.0(:\d+)?$/.test(origin) ||
    /^http:\/\/192\.168\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin) ||
    /^http:\/\/10\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin) ||
    /^http:\/\/172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}(:\d+)?$/.test(origin)
  );
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const logger = new Logger('Bootstrap');

  app.setGlobalPrefix('api/v1');

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(
    new LoggingInterceptor(),
    new TransformInterceptor(),
  );

  const allowedOrigins = normalizeOrigins(process.env.CORS_ORIGINS);

  app.enableCors({
    origin: (
      origin: string | undefined,
      callback: (err: Error | null, allow?: boolean) => void,
    ) => {
      if (!origin) {
        return callback(null, true);
      }

      if (allowedOrigins.includes(origin)) {
        return callback(null, true);
      }

      if (process.env.NODE_ENV !== 'production' && isDevelopmentOrigin(origin)) {
        return callback(null, true);
      }

      logger.warn(`Blocked CORS origin: ${origin}`);
      return callback(new Error(`CORS: ${origin} not allowed`), false);
    },
    credentials: true,
  });

  const port = Number(process.env.PORT || 3000);
  await app.listen(port, '0.0.0.0');

  logger.log(`OMNIGO Core API running on port ${port}`);
}

bootstrap().catch((error) => {
  const logger = new Logger('Bootstrap');
  logger.error('Failed to start OMNIGO Core API', error?.stack || error);
  process.exit(1);
});