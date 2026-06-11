import { Query, Resolver } from '@nestjs/graphql';
import { Public } from '../auth/decorators/public.decorator';

@Resolver()
export class HealthResolver {
  @Query(() => String)
  @Public()
  healthCheck(): string {
    return `omnigo-core-api OK @ ${new Date().toISOString()}`;
  }
}
