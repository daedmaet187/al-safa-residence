# Code Review — Al-Safa Residence

Date: 2026-04-29  
Reviewer: Claude Code

## Verdict: FAIL

9 critical issues must be fixed before any production deployment. Two are privilege-escalation vectors; one renders the admin dashboard completely non-functional.

---

## CRITICAL Issues (must fix before deploy)

### [CRIT-001] Hardcoded JWT secret fallbacks — token forgery if env var missing
**Layer**: backend  
**File**: `backend/src/config/configuration.ts` (lines 8–9)  
**Issue**: `JWT_ACCESS_SECRET` falls back to `'access-secret'` and `JWT_REFRESH_SECRET` to `'refresh-secret'`. If the environment variables are absent at startup (misconfigured ECS task, missing Secrets Manager injection), the application runs with publicly known signing keys. Any attacker can mint valid JWTs for any user and role.  
**Fix**: Remove both fallbacks entirely. Throw a startup error if either secret is undefined:
```ts
accessSecret: process.env.JWT_ACCESS_SECRET ?? (() => { throw new Error('JWT_ACCESS_SECRET is required') })(),
refreshSecret: process.env.JWT_REFRESH_SECRET ?? (() => { throw new Error('JWT_REFRESH_SECRET is required') })(),
```

---

### [CRIT-002] Wildcard CORS — any origin can make credentialed requests
**Layer**: backend  
**File**: `backend/src/main.ts` (line 19)  
**Issue**: `app.enableCors()` with no options defaults to `Access-Control-Allow-Origin: *`. Combined with the JWT-in-header pattern this is lower risk than cookies, but it still allows any website to make API requests using a user's token if obtained via XSS, and removes the browser-enforced origin barrier entirely.  
**Fix**:
```ts
app.enableCors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') ?? ['https://safa-admin.stuff187.com', 'https://safa.stuff187.com'],
  credentials: true,
});
```

---

### [CRIT-003] PATCH /users/:id missing @Roles() — any resident can escalate to ADMIN
**Layer**: backend  
**File**: `backend/src/users/users.controller.ts` (line 75)  
**Issue**: `PATCH /users/:id` has `JwtAuthGuard` and `RolesGuard` applied at the controller level, but no `@Roles()` decorator on the method. `RolesGuard.canActivate()` returns `true` when `requiredRoles` is null/empty (roles.guard.ts line 16). Result: any authenticated resident or security guard can call `PATCH /users/:id` with `{ "role": "ADMIN" }` and elevate their own account. They can also overwrite any other user's email or password.  
**Fix**: Add `@Roles(Role.ADMIN)` to `PATCH /users/:id`. If residents need to update their own profile (name, phone, password), add a separate `PATCH /users/me` endpoint with ownership enforcement.

---

### [CRIT-004] GET /users/:id missing @Roles() — any authenticated user reads all user PII
**Layer**: backend  
**File**: `backend/src/users/users.controller.ts` (line 66)  
**Issue**: Same missing `@Roles()` pattern. Any authenticated user can call `GET /users/:id` for any UUID and receive name, email, phone, role, and unit assignments. A resident can enumerate all other residents' contact details.  
**Fix**: Add `@Roles(Role.ADMIN)`, or add an ownership check that restricts residents to only fetching their own record (`if (user.role !== 'ADMIN' && id !== user.id) throw new ForbiddenException()`).

---

### [CRIT-005] Admin dashboard calls non-existent endpoint /auth/admin/login — login is broken
**Layer**: admin  
**File**: `admin/src/app/login/index.tsx` (line 29)  
**Issue**: The admin login page calls `api.post('/auth/admin/login', values)`. The backend `AuthController` only exposes `POST /auth/login`; there is no `/auth/admin/login` route. Every admin login attempt will receive a 404. The admin dashboard is currently non-functional.  
**Fix**: Change the call to `api.post('/auth/login', values)`. Additionally, after a successful login, validate that `data.user.role === 'ADMIN'` before calling `setToken()` — otherwise a resident could log into the admin dashboard with their own credentials and get partial access.

---

### [CRIT-006] POST /payments/autopay missing user context — authorization bypass
**Layer**: backend  
**File**: `backend/src/payments/payments.controller.ts` (lines 87–92)  
**Issue**: The `configureAutopay` handler has no `@User()` decorator. The service receives only `dto: AutopayDto` with no userId. The endpoint accepts any authenticated request and cannot associate the configuration with a specific user. The service implementation is a stub that echoes the DTO, but the absence of user context means this endpoint is structurally broken and will need to be rewritten before use.  
**Fix**: Add `@User() user: any` parameter; pass `user.id` to the service method. The service must validate that the user owns the unit or bill being configured for autopay.

---

### [CRIT-007] S3 presigned URL — no per-user path restriction, no file size limit
**Layer**: backend  
**File**: `backend/src/uploads/uploads.service.ts` (lines 36–54)  
**Issue**: Any authenticated user can request a presigned PUT URL for any S3 key. A resident can overwrite another resident's uploaded ID document by requesting `users/<other-user-id>/id-front.jpg`. There is also no `ContentLength` condition on the `PutObjectCommand`, so users can upload arbitrarily large files to the bucket. Additionally, the response includes `bucket: this.bucket`, leaking the internal bucket name.  
**Fix**:
1. Enforce that `dto.key` starts with a user-owned prefix: `uploads/${user.id}/` for residents, or validate against allowed prefixes per role.
2. Add a `ContentLengthRange` condition to the presigned URL (max 20MB for images, 5MB for PDFs).
3. Remove `bucket` from the response object — the client only needs `url` and `key`.

---

### [CRIT-008] Mobile has no GoRouter route guards — all screens accessible without auth
**Layer**: mobile  
**File**: `mobile/lib/core/router/app_router.dart`  
**Issue**: The GoRouter has no `redirect` callback. All routes — `/home`, `/home/gate`, `/home/payments`, `/security`, `/security/scan`, etc. — are registered without any auth check. The splash screen (`/`) checks auth state and navigates accordingly, but GoRouter does not protect against direct navigation (deep links, back/forward gestures, programmatic `context.go()`). An unauthenticated user can deep-link directly to any screen.  
**Fix**: Add a top-level `redirect` callback to the `GoRouter` that checks `SecureStorage.getAuthToken()` and redirects to `/login` for all protected routes:
```dart
redirect: (context, state) async {
  final token = await SecureStorage.getAuthToken();
  final isPublic = ['/login', '/onboarding', '/otp', '/biometric', '/security/login', '/'].contains(state.matchedLocation);
  if (token == null && !isPublic) return '/login';
  return null;
},
```

---

### [CRIT-009] Used guest pass can be scanned again — USED status not checked in scanQr
**Layer**: backend  
**File**: `backend/src/guests/guests.service.ts` (lines 100–117)  
**Issue**: `scanQr` checks for `REVOKED` and `EXPIRED` statuses (and date expiry), but never checks for `USED`. After a pass is approved the first time, it is set to `status: USED` (line 130). On subsequent scans within the validity window, none of the status checks match, and the result falls through to `APPROVED`. A guest pass can be reused indefinitely as long as `validUntil` has not passed.  
**Fix**: Add a USED check alongside the existing status checks:
```ts
} else if (pass.status === GuestPassStatus.USED) {
  result = 'DENIED';
  reason = 'Pass has already been used';
}
```
If multi-use passes are a product requirement, remove the `status: USED` update and rely solely on `validUntil`.

---

## WARNINGS (should fix before v1)

### [WARN-001] No rate limiting on auth endpoints — brute-force risk
**Layer**: backend  
**File**: `backend/src/auth/auth.controller.ts`  
**Issue**: `POST /auth/login` and `POST /auth/refresh` have no throttling. An attacker can attempt unlimited password guesses or refresh token enumeration with no delay.  
**Fix**: Install `@nestjs/throttler`. Apply `@Throttle({ default: { limit: 5, ttl: 60000 } })` on `/auth/login` and `/auth/refresh`. Consider a stricter per-IP limit using a Redis store in production.

---

### [WARN-002] Admin login accepts any role — resident can access admin UI shell
**Layer**: admin  
**File**: `admin/src/app/login/index.tsx` (lines 32–35)  
**Issue**: After fixing CRIT-005, the login still only checks for the presence of an access token; it never inspects the `role` claim in the JWT or in `data.user`. A resident or security guard who knows the admin URL can authenticate successfully and reach the dashboard shell. The backend blocks most data operations, but the UI is exposed and the user can observe partial data from unguarded endpoints.  
**Fix**: In `onSuccess`, check `data.user.role === 'ADMIN'`. If not, call `toast.error('Access denied')` and do not store the token. Alternatively, decode the JWT on the client and verify the role claim before storing.

---

### [WARN-003] Security guard login stores no refresh token — guards logged out mid-shift
**Layer**: mobile  
**File**: `mobile/lib/features/security/providers/security_provider.dart` (login handler)  
**Issue**: The security login handler stores only the access token. With a 15-minute JWT expiry, guards will be silently logged out during active shifts. There is no refresh flow for the security role.  
**Fix**: Store the refresh token from the login response and reuse the same `DioClient` 401-retry interceptor that handles resident sessions.

---

### [WARN-004] OTP resend is an empty stub; no brute-force protection on OTP verification
**Layer**: mobile  
**File**: `mobile/lib/features/auth/screens/otp_screen.dart` (line 160)  
**Issue**: The "Resend code" button handler is `onPressed: () {}` — nothing happens. More critically, there is no attempt counter or lockout on OTP submission, so an attacker can brute-force a 6-digit OTP (1M combinations) without any server-side rate limiting being visible on the client.  
**Fix**: Implement the resend call with a 60-second cooldown timer. Add attempt tracking in the provider and lock the screen after 5 failed attempts. The backend OTP endpoint should enforce its own rate limit independently.

---

### [WARN-005] Missing database indexes on frequently queried foreign key columns
**Layer**: backend  
**File**: `backend/prisma/schema.prisma`  
**Issue**: The following foreign key columns are queried in every list and detail operation but have no index: `MaintenanceRequest.userId`, `MaintenanceRequest.unitId`, `Bill.userId`, `Bill.unitId`, `Payment.userId`, `Payment.billId`, `GateLog.guestPassId`, `DeviceToken.userId`, `UnitAssignment.userId`. These will become full-table scans as the tenant base grows.  
**Fix**: Add `@@index` declarations to each affected model, e.g.:
```prisma
model Bill {
  ...
  @@index([userId])
  @@index([unitId])
}
```

---

### [WARN-006] Guest pass QR code is a bare UUID — no cryptographic signature
**Layer**: backend / mobile  
**File**: `backend/src/guests/guests.service.ts` (line 19); `mobile/lib/features/gate/`  
**Issue**: The QR payload is a raw UUIDv4 (`qrCode = uuidv4()`). While UUIDs are probabilistically hard to guess, they carry no tamper evidence. A compromised device, a screenshot of the QR, or a database read gives the attacker a fully working pass that the scan endpoint accepts indefinitely. There is no validity window tied to the token itself.  
**Fix**: Sign the UUID with an HMAC-SHA256 using the JWT access secret: `qrPayload = uuid + '.' + hmac(uuid, secret)`. The scan endpoint verifies the signature before looking up the pass. This ties QR validity to server-side key rotation.

---

### [WARN-007] Soft delete inconsistency — most models support hard delete only
**Layer**: backend  
**File**: `backend/prisma/schema.prisma`  
**Issue**: `User` and `Announcement` have `deletedAt` fields (soft delete). `Unit`, `Bill`, `Payment`, `MaintenanceRequest`, and `GuestPass` do not. Deleting a bill or maintenance request permanently removes audit history and risks breaking foreign key references in `Payment` and `GateLog`.  
**Fix**: Add `deletedAt DateTime?` to `Unit`, `Bill`, `Payment`, `MaintenanceRequest`. Update all corresponding service `remove` methods to set `deletedAt` rather than call `prisma.model.delete()`. Add `where: { deletedAt: null }` to all `findMany` queries in those services.

---

### [WARN-008] No global exception filter — stack traces may leak in error responses
**Layer**: backend  
**File**: `backend/src/main.ts`  
**Issue**: There is no `app.useGlobalFilters()` registration. NestJS's default exception handler may include stack traces and internal error details in non-production-recognized environments. If `NODE_ENV` is not set correctly on ECS, structured error info could be exposed to API consumers.  
**Fix**: Create a `HttpExceptionFilter` that strips stack traces in production and returns `{ statusCode, message, timestamp }` only. Register it globally in `main.ts`.

---

### [WARN-009] Biometric fallback silently skips to home — no re-authentication
**Layer**: mobile  
**File**: `mobile/lib/features/auth/screens/biometric_screen.dart`  
**Issue**: If biometrics are unavailable or the check fails, the user is silently navigated to the home screen without any alternative authentication challenge. A user who enables biometric on setup and later uses a device where biometrics fail (e.g., after restoring a backup) gets into the app without any credential check.  
**Fix**: On biometric failure or unavailability, prompt for password re-entry rather than silently proceeding. The "Skip for now" path on first setup is acceptable, but post-setup failures must fall back to credential verification.

---

### [WARN-010] GET /units/:id accessible to all authenticated users — unit PII exposure
**Layer**: backend  
**File**: `backend/src/units/units.controller.ts`  
**Issue**: `GET /units/:id` has no `@Roles()` decorator. Any authenticated user can retrieve full unit details including all resident assignments (`UnitAssignment` includes) — effectively mapping which resident lives in which unit.  
**Fix**: Add `@Roles(Role.ADMIN)`, or restrict to users assigned to that unit: query `UnitAssignment` before returning the full unit record.

---

### [WARN-011] Refresh token DB expiry hardcoded to +7 days, independent of JWT_REFRESH_EXPIRY
**Layer**: backend  
**File**: `backend/src/auth/auth.service.ts` (line 86)  
**Issue**: `expiresAt.setDate(expiresAt.getDate() + 7)` is hardcoded. If `JWT_REFRESH_EXPIRY` is changed to `30d` (or `1d`), the database expiry check still uses 7 days — creating a mismatch where the JWT is valid but the DB record is expired or vice versa.  
**Fix**: Parse `JWT_REFRESH_EXPIRY` config value to compute `expiresAt` dynamically, or define a single `REFRESH_TOKEN_TTL_DAYS` constant used by both the JWT sign call and the DB record.

---

## NOTES (optional improvements)

### [NOTE-001] API base URL hardcoded in mobile and admin
`mobile/lib/core/network/dio_client.dart` and `admin/src/lib/axios.ts` both hardcode `https://safa-api.stuff187.com/api`. Fine for single-environment deployments, but switch to a build-time env variable (`--dart-define` for Flutter, `VITE_API_URL` for Vite) to enable staging/preview environments without code changes.

### [NOTE-002] Admin 401 handler logs user out instead of attempting token refresh
`admin/src/lib/axios.ts` clears the token on 401 and redirects to login. The backend issues refresh tokens but the admin never uses them. Add a refresh interceptor (attempt `POST /auth/refresh` on first 401; retry original request; redirect on second 401) to avoid unnecessary admin session drops.

### [NOTE-003] Presigned URL 5-minute window is correct; response body structure leaks bucket name
The 5-minute expiry on the S3 presigned URL (`expiresIn: 300`) is appropriate. Remove the `bucket` field from the response (uploads.service.ts line 48) — the client has no legitimate use for the bucket name and it reduces the information surface.

### [NOTE-004] flutter_secure_storage used correctly
Tokens stored in `flutter_secure_storage` with `AndroidOptions(encryptedSharedPreferences: true)`. This is the correct approach. The `shared_preferences` package is included as a dependency but not used for tokens — safe to remove to reduce the attack surface.

### [NOTE-005] Auth service correctly prevents user enumeration
`auth.service.ts` returns the same generic `"Invalid credentials"` message for wrong email and wrong password. This is correct behavior.

### [NOTE-006] ValidationPipe global config is correct
`whitelist: true`, `transform: true`, `forbidNonWhitelisted: true` applied globally. This is the correct configuration; no DTO validation issues were found.

### [NOTE-007] Refresh token rotation correctly implemented
On refresh, the old token is deleted from the database before issuing a new one (auth.service.ts line 61). This prevents replay attacks on stolen refresh tokens.

### [NOTE-008] Announcement edit button is a dead stub in admin UI
`admin/src/routes/_layout/announcements/index.tsx` renders an Edit button but the handler is not wired up. Either wire it or remove the button before launch.

### [NOTE-009] bcrypt rounds=12 is acceptable
12 rounds (~250ms on modern hardware) is within acceptable range for a property management platform. Consider 13–14 for a more security-sensitive context.

### [NOTE-010] Guest pass USED-on-first-scan design choice should be documented
If single-use passes are intentional (e.g., guest leaves after one scan), document this in the GuestPass model. If a pass is meant to allow multiple entries within the validity window, remove the `status: USED` update from `scanQr` and rely on `validUntil` alone (and fix CRIT-009 accordingly).

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 9 |
| WARNINGs | 11 |
| NOTES | 10 |

### Top priorities before deploy
1. **CRIT-005** — Admin login calls a 404 endpoint; fix first or the dashboard cannot be tested
2. **CRIT-003** — Any resident can self-escalate to ADMIN
3. **CRIT-001** — JWT secret fallbacks allow token forgery if env vars missing
4. **CRIT-009** — Guest pass reusable indefinitely within validity window
5. **CRIT-008** — Mobile screens have no auth gate (deep links bypass login)
