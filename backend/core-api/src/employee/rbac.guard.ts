import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { GqlExecutionContext } from '@nestjs/graphql';
import { RbacService } from './rbac.service';

export const PERMISSIONS_KEY = 'permissions';

/** Decorator: require specific permissions */
export const RequirePermissions = (...permissions: string[]) =>
  Reflect.metadata(PERMISSIONS_KEY, permissions);

@Injectable()
export class RbacGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private rbacService: RbacService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(
      PERMISSIONS_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!requiredPermissions || requiredPermissions.length === 0) {
      return true;
    }

    let req: any;
    const type = context.getType<string>();
    if (type === 'graphql') {
      const ctx = GqlExecutionContext.create(context);
      req = ctx.getContext().req;
    } else {
      req = context.switchToHttp().getRequest();
    }

    const user = req.user;
    if (!user?.tenantId) throw new ForbiddenException('No tenant context');

    for (const perm of requiredPermissions) {
      const has = await this.rbacService.hasPermission(
        user.tenantId,
        user.id,
        perm,
      );
      if (!has) {
        throw new ForbiddenException(`Missing permission: ${perm}`);
      }
    }

    return true;
  }
}
