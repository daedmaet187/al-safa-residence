# Phase 2 Bug Fix Results
Date: 2026-05-18

## Summary

All 4 high-priority fix groups implemented. Backend tests: 26/26 pass. Admin: builds clean. Flutter: not installed in environment (mobile tests could not be run).

---

## FIX-05: Payment history UX ✅

**Files changed:**
- `mobile/lib/features/payments/screens/payment_history_screen.dart`
  - Added `import 'package:go_router/go_router.dart'`
  - Added `onTap: () => context.push('/home/payments/${bill.id}')` to each ListTile
- `mobile/lib/features/payments/screens/bill_detail_screen.dart`
  - Added `if (bill.status == BillStatus.paid && bill.paidAt != null)` text block after the "Due [date]" row in the header card

---

## FIX-06: Chat timestamps + close ticket ✅

**Files changed:**
- `mobile/lib/features/chat/screens/conversation_screen.dart`
  - Added `go_router` import
  - Added top-level `_formatMessageTime()` helper: today → `h:mm a`, older → `d MMM, h:mm a`
  - `_MessageBubble` now uses `_formatMessageTime(message.createdAt)` instead of `timeFmt.format(...)`
  - Added `_closeTicket()` method to `_ConversationScreenState` (confirmation dialog → PATCH close → pop)
  - Added `actions` to AppBar: shows "Close" TextButton when `convAsync.valueOrNull?.status == 'open'`
- `mobile/lib/features/chat/screens/chat_screen.dart`
  - Added top-level `_formatConvDate()` helper: today → `h:mm a`, this year → `d MMM`, older → `d MMM y`
  - Replaced `DateFormat('MMM d')` inline with `_formatConvDate(conv.updatedAt)`
- `backend/src/chat/chat.service.ts`
  - Added `closeConversation(residentId, conversationId)` method with ownership check and idempotency guard
- `backend/src/chat/chat.controller.ts`
  - Added `PATCH conversations/:id/close` endpoint calling `chatService.closeConversation()`
- `mobile/lib/features/chat/providers/chat_provider.dart`
  - Added `close()` method to `ConversationDetailNotifier`: PATCH → invalidates both detail and list providers

---

## FIX-07: Admin Edit stubs ✅

**Files changed:**
- `admin/src/app/residents/-components/list/table.tsx`
  - Added `EditResidentDialog` component with name, phone, status fields using `useUpdateResident(id)`
  - Added `useState(false)` for dialog visibility inside `ActionsCell`
  - Wired `DropdownMenuItem` Edit `onClick` to open the dialog
- `admin/src/app/announcements/index.tsx`
  - Added `EditAnnouncementDialog` component (pre-populated with existing announcement data) using `useUpdateAnnouncement(id)`
  - Added `useState<Announcement | null>` for `editingAnnouncement` in `AnnouncementsPage`
  - Wired Edit `Button` in `AnnouncementCard` to call `onEdit(announcement)` via prop
  - Added "Expired" badge to cards where `expiresAt < now`
  - `useUpdateAnnouncement` was already implemented in the service — just imported it

**Backend note:** `PATCH /admin/announcements/:id` and `PATCH /admin/residents/:id` already existed in `admin.controller.ts`.

---

## FIX-08: Filter expired announcements ✅

**Files changed:**
- `backend/src/resident/resident.service.ts` — `getDashboardSummary()`
  - Added `OR: [{ expiresAt: null }, { expiresAt: { gt: now } }]` to the announcement `findMany` where clause
  - Changed `orderBy` from `{ publishedAt: 'desc' }` to `[{ isImportant: 'desc' }, { publishedAt: 'desc' }]`

**Already fixed:** `backend/src/announcements/announcements.service.ts` `findAll()` (serves `GET /announcements` for mobile community screen) already had the expiry filter implemented — no change needed.

**Admin list unchanged:** Admin list (`admin.service.ts getAnnouncements()`) intentionally shows all announcements with no expiry filter so staff can manage them. Added "Expired" badge client-side in `AnnouncementCard`.

---

## Test Results

| Suite | Result |
|---|---|
| backend: `npm test` | ✅ 26/26 passed |
| admin: `npm run build` (no test script) | ✅ Built clean |
| mobile: `flutter test` | ⚠️ flutter not installed in environment |
