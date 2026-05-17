# Warnings Fix Plan — Al-Safa Residence

Date: 2026-05-17
Target: Fix all 11 WARNINGs from REVIEW.md before v1 launch

---

## WARN-001 — Rate limiting on auth endpoints

**File**: `backend/src/auth/auth.controller.ts`, `backend/src/app.module.ts`, install `@nestjs/throttler`
- Install `@nestjs/throttler`
- Import and configure `ThrottlerModule.forRoot([{ ttl: 60000, limit: 5 }])` in `app.module.ts`
- Add `ThrottlerGuard` as global guard OR apply `@Throttle({ default: { limit: 5, ttl: 60000 } })` on `/auth/login` and `/auth/refresh`

## WARN-002 — Admin login role check

**File**: `admin/src/app/login/index.tsx`
- After successful login, check `data.user.role === 'ADMIN'`
- If not ADMIN: show `toast.error('Access denied — admin credentials required')`, do not store token, do not redirect

## WARN-003 — Security guard refresh token

**File**: `mobile/lib/features/security/providers/security_provider.dart`
- Store refresh token from login response in `SecureStorage`
- Reuse the same Dio 401-retry interceptor used by the resident flow to auto-refresh tokens

## WARN-004 — OTP resend + brute-force protection

**File**: `mobile/lib/features/auth/screens/otp_screen.dart`
- Implement resend button: call the resend OTP API with a 60-second countdown timer
- Add attempt counter in provider; lock screen after 5 failed attempts with error message

## WARN-005 — Missing DB indexes

**File**: `backend/prisma/schema.prisma`
Add `@@index` to:
- `MaintenanceRequest`: `[userId]`, `[unitId]`
- `Bill`: `[userId]`, `[unitId]`
- `Payment`: `[userId]`, `[billId]`
- `GateLog`: `[guestPassId]`
- `DeviceToken`: `[userId]`
- `UnitAssignment`: `[userId]`

After updating schema, generate and apply a new migration:
```
npx prisma migrate dev --name add_fk_indexes
```

## WARN-006 — HMAC-signed guest pass QR

**File**: `backend/src/guests/guests.service.ts`, `backend/src/guests/guests.service.ts` scan handler
- On QR generation: `qrPayload = uuid + '.' + hmac-sha256(uuid, JWT_ACCESS_SECRET)`
- On `scanQr`: split on `.`, verify HMAC before DB lookup; reject with DENIED if signature invalid
- Use Node.js built-in `crypto` module (no new deps)

## WARN-007 — Soft delete consistency

**Files**: `backend/prisma/schema.prisma`, affected service files
- Add `deletedAt DateTime?` to: `Unit`, `Bill`, `Payment`, `MaintenanceRequest`
- Update `remove()` methods in `units.service.ts`, `bills.service.ts`, `payments.service.ts`, `maintenance.service.ts` to set `deletedAt = new Date()` instead of hard delete
- Add `where: { deletedAt: null }` filter to all `findMany` queries in those services
- Generate and apply migration: `npx prisma migrate dev --name add_soft_delete`

## WARN-008 — Global HTTP exception filter

**Files**: `backend/src/filters/http-exception.filter.ts` (new), `backend/src/main.ts`
- Create `HttpExceptionFilter` that returns `{ statusCode, message, timestamp }` only (no stack traces in production)
- Register with `app.useGlobalFilters(new HttpExceptionFilter())`

## WARN-009 — Biometric fallback to credentials

**File**: `mobile/lib/features/auth/screens/biometric_screen.dart`
- On biometric failure (non-first-setup): navigate to password re-entry screen instead of home
- First-setup "skip" path remains acceptable

## WARN-010 — GET /units/:id role restriction

**File**: `backend/src/units/units.controller.ts`
- Add `@Roles(Role.ADMIN)` to `GET /units/:id`, OR add ownership check: only return if user is assigned to that unit
- Recommendation: add ADMIN-only for the full detail endpoint; add a separate `GET /units/mine` for residents that returns only their assigned unit(s)

## WARN-011 — Refresh token expiry sync

**File**: `backend/src/auth/auth.service.ts`
- Define a constant or derive TTL from `JWT_REFRESH_EXPIRY` config value
- Use same value for both `sign({ expiresIn: ... })` and the DB `expiresAt` calculation

---

## Notes

- After WARN-005 and WARN-007, run: `npx prisma migrate dev` and commit migrations
- After all fixes: run the full test suite (`npm test` in backend, `npm test` in admin, `flutter test` in mobile)
- Update HANDOFF.md "Known Limitations" section to mark all 11 warnings as resolved
- Commit with message: `fix: address all 11 warnings from code review (WARN-001 through WARN-011)`
