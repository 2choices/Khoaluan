import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { GqlExecutionContext } from '@nestjs/graphql';
import { AuthenticatedUser } from '../strategies/supabase-jwt.strategy';

/** Extract the authenticated user from the request */
export const CurrentUser = createParamDecorator(
  (data: keyof AuthenticatedUser | undefined, context: ExecutionContext) => {
    let req: any;
    const type = context.getType<string>();
    if (type === 'graphql') {
      const ctx = GqlExecutionContext.create(context);
      req = ctx.getContext().req;
    } else {
      req = context.switchToHttp().getRequest();
    }
    const user: AuthenticatedUser = req.user;
    return data ? user?.[data] : user;
  },
);
