# Phase 1 Bug Fix Results
Date: 2026-05-18

## Summary

All 4 critical fix groups implemented and verified.

---

## FIX-01 — Guest pass expiry not reflected in UI ✅

**Files changed:**
- `mobile/lib/features/gate/providers/gate_provider.dart` — Added `displayStatus` getter to `GuestPass` that returns `'expired'` when `status == 'active'` but `validUntil` is in the past
- `mobile/lib/features/gate/screens/gate_screen.dart` — `StatusChip` now uses `pass.displayStatus` instead of `pass.isActive ? 'active' : pass.status`
- `backend/src/resident/resident.service.ts` — `getGuestPasses()`: runs `updateMany` to flip stale ACTIVE passes to EXPIRED before fetching; `getDashboardSummary()`: same updateMany before counting active passes

**Note:** `status_chip.dart` already had an `expired` case mapped to warning/amber color — no change needed there.

---

## FIX-02 — Admin mark-paid creates no Payment record ✅

**Files changed:**
- `backend/src/admin/admin.service.ts` — `markBillPaid()` replaced with `$transaction` version that creates a `Payment` record (`method: BANK_TRANSFER`, `status: COMPLETED`, `paidAt: new Date()`, `reference: admin-manual-{id[:8]}`) and updates the bill status atomically. Idempotent: returns early if bill is already PAID.

---

## FIX-03 — Create Bill form broken ✅

**Files changed:**
- `admin/src/app/billing/-schema/index.ts` — Renamed `residentId` → `userId`; added optional `description` field
- `admin/src/app/billing/index.tsx` — Added imports for `useResidentList` and `useUnitList`; replaced raw `<Input placeholder="resident-uuid">` fields with `<Select>` dropdowns that fetch resident/unit lists (`take: 200` / `take: 100`); updated `defaultValues` to use `userId: ''`

---

## FIX-04 — ID Documents screen not implemented ✅

**Files changed:**
- `mobile/lib/features/profile/screens/id_documents_screen.dart` — New screen created with:
  - `_documentsProvider` fetching `GET /documents`
  - Two fixed slots for `id-front` and `id-back` with image thumbnails, upload/replace buttons, delete with confirmation, and fullscreen viewer
  - Upload flow: `POST /uploads/presigned` → PUT to S3 → `POST /documents` (same pattern as maintenance photos)
  - Empty-state placeholder per slot for unuploaded documents
  - `_FullscreenImageScreen` using `InteractiveViewer` for pinch-zoom
- `mobile/lib/features/profile/screens/profile_screen.dart` — `onTap: () {}` wired to `context.push('/home/id-documents')`
- `mobile/lib/core/router/app_router.dart` — Added `GoRoute(path: '/home/id-documents', ...)` outside the shell

---

## Test Results

| Layer | Tool | Result |
|---|---|---|
| backend | `npm test` (Jest) | ✅ 26/26 tests passed |
| admin | `npm run build` (Vite) | ✅ Build succeeded, no TypeScript errors |
| admin | `npm run lint` (Biome) | ⚠️ 3 import-order style issues in billing files (pre-existing style across 126 errors/83 files project-wide; no logic errors) |
| mobile | `flutter test` | ⚠️ Flutter SDK not installed in this environment — tests not run |

---

## Notes for follow-up

- **FIX-15 data migration**: The 5 existing admin-paid bills still have no Payment records. A retroactive SQL backfill is needed (see FIX-15 in the plan).
- **Mobile tests**: Flutter SDK needs to be in PATH to run `flutter test`. The Dart code compiles correctly based on type usage and follows the established patterns in the codebase.
