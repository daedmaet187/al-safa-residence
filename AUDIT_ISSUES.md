# Al-Safa Residence — Issues Found During Development

This document catalogs all bugs, mismatches, and issues discovered during testing.
Use this to audit the codebase and update the AI Factory to prevent recurrence.

---

## Category 1: API Response Field Mismatches

### 1.1 `user` vs `resident` naming
- **Problem**: Backend returned `bill.user`, `maintenance.user`, `guestPass.user`
- **Expected**: Dashboard TypeScript types expect `bill.resident`, `maintenance.resident`, `guestPass.resident`
- **Fix**: Backend maps `user` → `resident` in response DTOs

### 1.2 `assignments` vs `residents` on units
- **Problem**: Backend returned `unit.assignments[]` with nested user
- **Expected**: Dashboard expects `unit.residents[]` with flat structure
- **Fix**: Backend maps assignments to flat residents array

### 1.3 `adminNote` vs `notes` field
- **Problem**: Backend stores and returns `notes` field on MaintenanceRequest
- **Expected**: Mobile model mapped `json['adminNote']`
- **Fix**: Mobile model now reads `json['notes'] ?? json['adminNote']`

### 1.4 Missing `timeline`, `photos`, `adminNotes` in maintenance response
- **Problem**: Dashboard expected `request.timeline`, `request.photos`, `request.adminNotes`
- **Backend returned**: Only raw Prisma fields without these computed fields
- **Crash**: `request.timeline.length` crashed when `timeline` was undefined
- **Fix**: Backend always returns `timeline: []`, `photos: []`, `adminNotes: ''`

---

## Category 2: Status/Enum Casing Mismatches

### 2.1 `in-progress` vs `in_progress` vs `IN_PROGRESS`
- **Backend enum**: `IN_PROGRESS` (Prisma enum, uppercase with underscore)
- **API response**: Was inconsistent — sometimes `in-progress`, sometimes `IN_PROGRESS`
- **Dashboard expected**: `in_progress` (lowercase with underscore) for `statusVariant` keys
- **Mobile expected**: Lowercase for display
- **Fix**: API always returns lowercase: `pending`, `in_progress`, `resolved`, `cancelled`

### 2.2 `monthly-fee` vs `monthly_fee` vs `MONTHLY_FEE`
- **Problem**: Bill types had similar casing inconsistency
- **Fix**: API returns lowercase with hyphens: `monthly-fee`, `utility`, `maintenance-fee`

### 2.3 Maintenance category enum mismatch
- **Backend enum**: `PLUMBING`, `ELECTRICAL`, `AC_HVAC`, etc. (uppercase)
- **Mobile was sending**: Display labels like "Plumbing", "AC/HVAC"
- **Fix**: Mobile sends exact enum values; displays labels in UI only

---

## Category 3: Pagination/Response Structure

### 3.1 Pagination wrapper inconsistency
- **Problem**: Some endpoints returned `{ data, total }`, others returned raw arrays
- **Dashboard expected**: `{ data, total, count, page, limit, totalPages }`
- **Fix**: All paginated endpoints use `paginate()` helper returning full pagination object

### 3.2 `/auth/me` response structure
- **Problem**: Backend returned `{ user }` but mobile expected `{ user, units }`
- **Fix**: `/auth/me` now returns `{ user, units }` with user's assigned units

---

## Category 4: Null Safety / Undefined Crashes

### 4.1 Gate passes — null resident/unit
- **Problem**: `row.original.resident.name` crashed when resident was null
- **Fix**: Added `?.` optional chaining: `row.original.resident?.name ?? '—'`

### 4.2 Maintenance timeline crash
- **Problem**: `request.timeline.length > 0` crashed when timeline undefined
- **Fix**: Changed to `(request.timeline ?? []).length > 0`

### 4.3 formatDate crash with dateStyle/timeStyle
- **Problem**: `Intl.DateTimeFormat` throws RangeError when mixing `dateStyle`/`timeStyle` with `year`/`month`/`day`
- **Code**: `formatDate(date, { dateStyle: 'medium', timeStyle: 'short' })` + default `{ year, month, day }` merged = crash
- **Fix**: Detect if opts has styleShorthand and skip merging defaults

---

## Category 5: Authentication / Session

### 5.1 Token cleared on network error
- **Problem**: Auth provider cleared token on ANY error, including network timeouts
- **Expected**: Only clear token on 401 Unauthorized
- **Fix**: Only clear on explicit 401 response

### 5.2 Biometric not triggering on app reopen
- **Problem**: Biometric only checked on login, not on app resume
- **Fix**: Added BiometricScreen that triggers on every app open (not just login)

### 5.3 JWT access token too short (15 min)
- **Problem**: 15 min token caused frequent re-logins during testing
- **Fix**: Extended to 24h for better UX (refresh token handles security)

---

## Category 6: Photo Upload

### 6.1 Local file paths instead of S3 URLs
- **Problem**: Mobile stored local paths (`/data/user/0/...`) in `photoUrls`
- **Expected**: S3 URLs that can be displayed anywhere
- **Fix**: Mobile now uploads to S3 via presigned URL, stores S3 URL

---

## Category 7: API Endpoint Paths

### 7.1 QR scan wrong endpoint
- **Problem**: Mobile called `/gate/scan` but endpoint was `/guests/scan`
- **Fix**: Changed mobile to call `/guests/scan`

### 7.2 NestJS route order
- **Problem**: Param routes (`:id`) defined before specific routes (`/stats`)
- **Result**: `/stats` matched as `id='stats'`, returned 404
- **Fix**: Define specific routes before param routes in controller

---

## Category 8: UI/UX Issues

### 8.1 Back button not showing
- **Problem**: Some screens used `context.go()` which replaces history
- **Expected**: `context.push()` to allow back navigation
- **Fix**: Changed to `context.push()` for sub-screens

### 8.2 onSeenOnboarding cleared on logout
- **Problem**: User sees onboarding again after logout/login
- **Fix**: Preserve `hasSeenOnboarding` in SecureStorage across logout

### 8.3 Markdown tables on Discord/WhatsApp
- **Problem**: Markdown tables render as garbage on messaging platforms
- **Note**: Admin dashboard is web-only, so tables are fine there

---

## Category 9: Gate/Security Module

### 9.1 Gate logs missing officer name
- **Problem**: API returned `guardId` but not guard's name
- **Fix**: Fetch guard user info and return `officer` field

### 9.2 Guest pass single-use
- **Requirement**: Pass should be consumed/expired after first successful scan
- **Status**: Backend already marks as USED — working correctly

---

## Category 10: Dashboard-Specific

### 10.1 Currency selector missing
- **Problem**: No way to change display currency in admin dashboard
- **Fix**: Added currency selector in sidebar (IQD/USD/EUR/AED/SAR)

### 10.2 Photos not displayed in maintenance dialog
- **Problem**: Admin couldn't see photos attached to maintenance requests
- **Fix**: Added photo gallery in status update dialog

---

## Root Causes Summary

| Root Cause | Frequency | Examples |
|---|---|---|
| Frontend/backend field name mismatch | HIGH | user vs resident, adminNote vs notes |
| Enum casing inconsistency | HIGH | IN_PROGRESS vs in_progress vs in-progress |
| Missing null guards | MEDIUM | timeline undefined, resident null |
| Incomplete API response | MEDIUM | Missing timeline, photos, adminNotes |
| Frontend hardcoded values not matching API | MEDIUM | Mobile category labels vs enum values |
| Auth token lifecycle issues | LOW | Clear on network error, short expiry |

---

## AI Factory Prevention Rules

Based on these issues, the AI Factory should enforce:

1. **Field naming convention**: Always use same field names in backend DTOs and frontend types
2. **Enum handling**: Backend returns lowercase; frontend maps to display labels separately
3. **Null safety**: All optional fields must use optional chaining in frontend
4. **Pagination wrapper**: All list endpoints return `{ data, total, count, page, limit, totalPages }`
5. **Auth response**: `/auth/me` always returns `{ user, units }` or `{ user, ...related }`
6. **File uploads**: Always upload to S3 first, never store local paths
7. **Route order**: Specific routes before param routes in NestJS
8. **Status codes**: Only clear auth token on 401, not on network errors
9. **API testing**: E2E tests must verify response structure matches frontend types
10. **Date formatting**: Never mix dateStyle/timeStyle with individual date fields
