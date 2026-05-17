# Warnings Fix Results — Al-Safa Residence

Date: 2026-05-17  
Engineer: Watson + Claude Code

---

## Summary

All 11 pre-launch warnings from REVIEW.md have been resolved. 6 were already implemented in prior sessions; 5 required new code changes in this session.

---

## Status by Warning

### Already Resolved (prior sessions)

| ID | Description | Status |
|----|-------------|--------|
| WARN-001 | Rate limiting on /auth/login and /auth/refresh | ✅ Done — `@Throttle` decorators in `auth.controller.ts`, `ThrottlerModule` in `app.module.ts` |
| WARN-002 | Admin login role check | ✅ Done — `data.user?.role !== 'ADMIN'` check in `admin/src/app/login/index.tsx` |
| WARN-003 | Security guard refresh token storage | ✅ Done — `storage.setRefreshToken()` called in `security_provider.dart` |
| WARN-004 | OTP resend + brute-force lockout | ✅ Done — 60s countdown timer and 5-attempt lockout in `otp_screen.dart` |
| WARN-005 | Missing DB indexes on FK columns | ✅ Done — all 6 `@@index` declarations added to `schema.prisma` |
| WARN-008 | Global HTTP exception filter | ✅ Done — `HttpExceptionFilter` registered in `main.ts`, file at `src/common/filters/http-exception.filter.ts` |

### Fixed in This Session

| ID | Description | Files Changed |
|----|-------------|---------------|
| WARN-006 | HMAC-signed guest pass QR — verify before DB lookup | `backend/src/guests/guests.service.ts`, `src/__tests__/guests.service.spec.ts` |
| WARN-007 | Soft delete on Unit, Bill, Payment, MaintenanceRequest | `backend/prisma/schema.prisma`, `units.service.ts`, `payments.service.ts`, `maintenance.service.ts`, migration SQL |
| WARN-009 | Biometric failure navigates to /login instead of home | `mobile/lib/features/auth/screens/biometric_screen.dart` |
| WARN-010 | GET /units/:id restricted to ADMIN role | `backend/src/units/units.controller.ts` |
| WARN-011 | Refresh token DB expiry parsed from JWT_REFRESH_EXPIRY | `backend/src/auth/auth.service.ts` |

---

## Change Details

### WARN-006
Added `this.verifyQr(dto.qrCode)` call at the top of `scanQr()`. Returns `DENIED` immediately if the HMAC signature doesn't match, before any DB lookup. Test file updated to compute valid signed QR codes using `crypto.createHmac('sha256', TEST_SECRET)`.

### WARN-007
- Added `deletedAt DateTime?` to `Unit`, `Bill`, `Payment`, `MaintenanceRequest` models in `schema.prisma`
- Added `remove()` / `removeBill()` / `removePayment()` soft-delete methods to respective services
- Added `deletedAt: null` filter to all `findMany` queries in `units.service.ts`, `payments.service.ts`, and `maintenance.service.ts`
- Created migration: `prisma/migrations/20260517000000_add_soft_delete/migration.sql`

### WARN-009
In `_verify()` (verify mode only, called when `alreadySetup = true`):
- Replaced `setState(() => _showPinFallback = true)` with `context.go('/login')` on all failure paths
- Changed "Use PIN instead" button to navigate to `/login`
- First-setup skip path (`_skip()`) unchanged — still navigates to home

### WARN-010
Added `@Roles(Role.ADMIN)` decorator to `GET /units/:id` handler in `units.controller.ts`.

### WARN-011
Added `parseExpiryMs(expiry: string)` helper that parses `'7d'`, `'30d'`, `'1h'` etc. to milliseconds. Used to compute `expiresAt = new Date(Date.now() + parseExpiryMs(refreshExpiry))` — now stays in sync with whatever `JWT_REFRESH_EXPIRY` is set to.

---

## Test Results

| Suite | Result |
|-------|--------|
| Backend (`npm test`) | ✅ 26/26 tests passed |
| Admin (`npm test`) | N/A — no test script; pre-existing biome lint warnings unrelated to these changes |
| Mobile (`flutter test`) | N/A — flutter not installed in this environment |
