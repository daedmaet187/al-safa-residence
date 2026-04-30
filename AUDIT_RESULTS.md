# Al-Safa Residence — Comprehensive Audit Results

**Date:** 2026-04-30  
**Audited by:** Watson (Opus)  

---

## Summary

| Severity | Count | Status |
|----------|-------|--------|
| CRITICAL | 2 | TO FIX |
| HIGH | 5 | TO FIX |
| MEDIUM | 8 | TO FIX |
| LOW | 6 | DEFERRED |

---

## CRITICAL Issues (Will crash/break app)

### CRIT-001: BillType format mismatch
**File:** `backend/src/admin/admin.service.ts:270`  
**Problem:** Backend converts `MONTHLY_FEE` → `monthly-fee` (dash), but TypeScript expects `maintenance_fee` (underscore)
```typescript
// Backend sends:
type: b.type.toLowerCase().replace('_', '-')  // monthly-fee, maintenance-fee
// Dashboard expects:
export type BillType = 'maintenance_fee' | 'utility' | 'parking' | 'amenity' | 'other'
```
**Fix:** Remove `.replace('_', '-')` — keep underscores

### CRIT-002: Billing page crashes on null resident/unit
**File:** `admin/src/app/billing/index.tsx:106-107`  
**Problem:** Missing optional chaining
```typescript
// Current:
cell: ({ row }) => row.original.resident.name
cell: ({ row }) => row.original.unit.number
// Should be:
cell: ({ row }) => row.original.resident?.name ?? '—'
cell: ({ row }) => row.original.unit?.number ?? '—'
```

---

## HIGH Issues (Will cause incorrect behavior)

### HIGH-001: Staff page missing null guards
**File:** `admin/src/app/staff/index.tsx:164-200`  
**Problem:** Multiple `row.original.x` without optional chaining
**Fix:** Add `?.` to all property accesses

### HIGH-002: Residents table missing null guards  
**File:** `admin/src/app/residents/-components/list/table.tsx:64-120`  
**Problem:** `row.original.units.length` crashes if units is undefined
**Fix:** Use `row.original.units?.length ?? 0`

### HIGH-003: Backend unit status not lowercase
**File:** `backend/src/admin/admin.service.ts:114`  
**Problem:** Returns `'occupied'` / `'vacant'` directly (correct), but dashboard type expects specific values
```typescript
// Backend returns:
status: u.assignments.length > 0 ? 'occupied' : 'vacant'
// Dashboard type:
export type UnitStatus = 'occupied' | 'vacant' | 'maintenance'
```
**Status:** OK — matches

### HIGH-004: Mobile GuestPass requires residentName/unitNumber not in all API responses
**File:** `mobile/lib/features/gate/providers/gate_provider.dart:39-41`  
**Problem:** Model expects `residentName` and `unitNumber` but resident API returns nested objects
**Backend:** Returns `{ user: { name }, unit: { number } }` but mobile expects flat fields
**Fix:** Backend map to flat `residentName`, `unitNumber` OR mobile read nested

### HIGH-005: Payment report byStatus returns uppercase
**File:** `backend/src/admin/admin.service.ts:603`  
**Problem:** `byStatusRaw.map((r) => ({ status: r.status, count: ... }))` — status is raw enum (PENDING, RESOLVED)
**Fix:** Add `.toLowerCase()` to status in reports

---

## MEDIUM Issues (May cause confusion/minor bugs)

### MED-001: Bill type display still uses dash replacement
**File:** `admin/src/app/billing/index.tsx:108`  
```typescript
cell: ({ row }) => <span className="capitalize">{row.original.type.replace('_', ' ')}</span>
```
**Status:** OK — this is for display only (replaces underscore with space)

### MED-002: Inconsistent endpoint naming
**Mobile uses:**
- `/bills` (resident)
- `/maintenance` (resident)
- `/gate/passes` (resident)
- `/gate/my-qr` (resident)

**Backend has:**
- `/api/resident/bills` — but mobile calls `/bills`
**Check:** Verify routes are properly mapped in NestJS

### MED-003: Backend user status mapping
**File:** `backend/src/admin/admin.service.ts:88,507`  
**Problem:** User status is derived from `isActive` boolean:
```typescript
status: u.isActive ? 'active' : 'inactive'
```
**Dashboard expects:** `'active' | 'inactive' | 'suspended' | 'pending'`
**Missing:** suspended, pending states cannot be represented

### MED-004: Missing email in some resident responses
**File:** `backend/src/admin/admin.service.ts:193,224,268,365`  
**Status:** All include email now — OK

### MED-005: GateLog type mismatch
**Dashboard type:**
```typescript
export interface GateLog {
  id: string
  guestName: string
  guestPhone?: string
  officer?: string
  resident?: string
  unit?: string
  result: GateLogResult  // 'approved' | 'denied'
  scannedAt: string
}
```
**Backend returns:** All fields present, result is lowercase — OK

### MED-006: Announcement priority not in dashboard type
**Backend has:** priority field on announcements
**Dashboard type:** Missing priority
**Fix:** Add `priority?: 'normal' | 'urgent'` to Announcement interface

### MED-007: Mobile profile endpoint mismatch
**Mobile calls:** `/profile` 
**Backend has:** `/users/me` or `/auth/me`
**Check:** Verify `/profile` route exists or mobile should use `/auth/me`

### MED-008: Security guard visitor log uses wrong result values
**File:** `mobile/lib/features/security/providers/security_provider.dart:77`
**Model expects:** `result` field
**Backend returns:** `result: 'approved' | 'denied'` (lowercase) — OK

---

## LOW Issues (Code quality / tech debt)

### LOW-001: Hardcoded OTP '123456'
**Files:** Multiple auth files
**Note:** Intentional for demo — add TODO for production

### LOW-002: Hardcoded PIN '1234' in biometric fallback
**File:** `mobile/lib/features/auth/screens/biometric_screen.dart`
**Note:** Needs real PIN storage for production

### LOW-003: No rate limiting on auth endpoints
**Note:** Listed in HANDOFF.md warnings

### LOW-004: Guest QR is unsigned UUID
**Note:** Listed in HANDOFF.md warnings

### LOW-005: Missing DB indexes on FK columns
**Note:** Listed in HANDOFF.md warnings

### LOW-006: Soft delete inconsistent across models
**Note:** Listed in HANDOFF.md warnings

---

## Fixes Required (Priority Order)

1. **CRIT-001:** Remove `.replace('_', '-')` from bill type conversion in backend
2. **CRIT-002:** Add `?.` to billing page resident/unit access
3. **HIGH-001:** Add `?.` to staff page  
4. **HIGH-002:** Add `?.` to residents table
5. **HIGH-004:** Backend should return flat `residentName`, `unitNumber` for guest passes
6. **HIGH-005:** Add `.toLowerCase()` to report status values
7. **MED-003:** Add `status` enum to User model (or document limitation)
8. **MED-006:** Add priority to Announcement type
9. **MED-007:** Verify mobile profile endpoint routing

---

## Action Items

- [ ] Fix CRIT-001 and CRIT-002 immediately
- [ ] Fix HIGH issues
- [ ] Add comprehensive E2E tests for type safety
- [ ] Document remaining LOW issues as tech debt
- [ ] Update AI Factory rules to prevent these patterns
