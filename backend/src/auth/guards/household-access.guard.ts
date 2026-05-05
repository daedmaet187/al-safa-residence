import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { REQUIRE_ACCESS_KEY, AccessTier } from '../decorators/require-access.decorator';

@Injectable()
export class HouseholdAccessGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<AccessTier | undefined>(
      REQUIRE_ACCESS_KEY,
      [context.getHandler(), context.getClass()],
    );

    // No @RequireAccess decorator — any valid JWT passes
    if (!required) return true;

    const { user } = context.switchToHttp().getRequest();
    if (!user) throw new ForbiddenException('Access denied');

    const actorType: string = user.actorType ?? 'resident';
    const accessLevel: string = user.accessLevel ?? 'FULL';

    if (required === 'PRIMARY_ONLY') {
      if (actorType !== 'resident') {
        throw new ForbiddenException('This feature is only available to the primary account holder');
      }
      return true;
    }

    if (required === 'FULL') {
      if (actorType === 'resident') return true;
      if (actorType === 'household_member' && accessLevel === 'FULL') return true;
      throw new ForbiddenException('Full access required for this feature');
    }

    // LIMITED — any authenticated actor can access
    return true;
  }
}
