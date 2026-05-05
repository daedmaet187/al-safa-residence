import { SetMetadata } from '@nestjs/common';

export type AccessTier = 'LIMITED' | 'FULL' | 'PRIMARY_ONLY';

export const REQUIRE_ACCESS_KEY = 'require_access';
export const RequireAccess = (tier: AccessTier) =>
  SetMetadata(REQUIRE_ACCESS_KEY, tier);
