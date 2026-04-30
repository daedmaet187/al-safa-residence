# Phase 4b: Test Results
Status: DONE
Backend tests: 26 passing
Mobile tests: 19 passing

## Backend (Jest)
- auth.service.spec.ts — 11 tests: login valid/invalid, refresh valid/expired/not-found, logout
- users.controller.spec.ts — 5 tests: ADMIN/RESIDENT RBAC on GET /:id and PATCH /:id
- guests.service.spec.ts — 5 tests: scanQr ACTIVE/USED/REVOKED/expired/non-existent
- uploads.service.spec.ts — 5 tests: RESIDENT correct prefix, ADMIN any prefix, wrong prefix, bad content-type, path traversal

## Mobile (flutter_test)
- auth_provider_test.dart — 3 tests: verifyOtp stores tokens, failure does not store, logout clears
- router_guard_test.dart — 8 tests: unauthenticated/authenticated redirect scenarios
- guest_pass_test.dart — 8 tests: GuestPass.fromJson, isActive, GateNotifier.createPass

## Bug fixed
Router redirect guard in app_router.dart had '/' in publicRoutes checked with
startsWith(), making every path public and disabling auth protection entirely.
Fixed to use exact match for '/' so only the splash route bypasses auth.
