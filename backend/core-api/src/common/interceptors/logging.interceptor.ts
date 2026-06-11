import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { GqlExecutionContext } from '@nestjs/graphql';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const type = context.getType<string>();
    const now = Date.now();

    if (type === 'graphql') {
      const gqlCtx = GqlExecutionContext.create(context);
      const info = gqlCtx.getInfo();
      return next
        .handle()
        .pipe(
          tap(() =>
            this.logger.log(
              `GraphQL ${info.parentType.name}.${info.fieldName} - ${Date.now() - now}ms`,
            ),
          ),
        );
    }

    const req = context.switchToHttp().getRequest();
    const { method, url } = req;
    return next
      .handle()
      .pipe(
        tap(() => this.logger.log(`${method} ${url} - ${Date.now() - now}ms`)),
      );
  }
}
