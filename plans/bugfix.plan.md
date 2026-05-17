# Bug Fix Plan — Al-Safa Residence
Generated: 2026-05-17  
Source: Friend's manual QA report (mobile + admin)  
Code verified against: mobile/, backend/, admin/ source

---

## Incorrectly Reported Bugs (skip these)

Before the fix tasks, the following bugs from the report were verified against the current code and are **already working correctly or the report is wrong**:

| Reported Bug | Reality |
|---|---|
| Help & Support tap does nothing | Correctly wired: `context.push('/home/support')` → `SupportScreen` (profile_screen.dart:147) |
| Admin Gate "Revoke" button does nothing | Wired to `useRevokeGuestPass()` mutation (gate/index.tsx:64) |
| Admin Billing "Pay" button does nothing | "Mark Paid" button is wired to `useMarkBillPaid()` (billing/index.tsx:115) |
| Admin Gate: guest name+phone concatenated in display | Admin shows name and phone in separate `<p>` elements; garbled names are test data in DB |
| Admin Staff: name+email concatenated | Separate `<p>` elements (staff/index.tsx:174-175) |
| Admin Staff: toast shows "active" | Toasts show "Staff created successfully" etc. (staff service.ts) |
| Admin Staff: form has no validation | Validation exists via Zod schema |
| Chat list sorts by creation not last message | Backend uses `orderBy: { updatedAt: 'desc' }` and both resident+admin send updates `updatedAt` on each message |
| Admin conversations: messages not counted | Test tooling selector issue, not a real bug |
| Admin conversations: no re-fetch after send | Query invalidation IS implemented (conversations service.ts) |
| Admin Maintenance: row click does nothing | A `MoreHorizontal` dropdown with "View & Update" dialog IS implemented |

---

## Severity Classification

| ID | Layer | Severity | Root Cause Cluster |
|---|---|---|---|
| FIX-01 | mobile | Critical | Guest pass expiry not reflected in UI |
| FIX-02 | backend | Critical | Admin mark-paid creates no Payment record |
| FIX-03 | admin | Critical | Create Bill form: field name mismatch + UUID text inputs |
| FIX-04 | mobile | Critical | ID Documents screen not implemented |
| FIX-05 | mobile | High | Payment history: no tap + bill detail no paid date |
| FIX-06 | mobile | High | Chat timestamps incomplete + no close action |
| FIX-07 | admin | High | Edit stubs: Residents Edit + Announcements Edit |
| FIX-08 | backend | High | Expired announcements not filtered from queries |
| FIX-09 | mobile | Medium | Pay Bills pushes stack instead of switching tab |
| FIX-10 | mobile | Medium | Gate UX: duplicate button + QR scrolls off screen |
| FIX-11 | admin | Medium | Create Resident/Bill 409 shows generic error |
| FIX-12 | mobile | Medium | Home guest pass badge count stale |
| FIX-13 | mobile | Low | Accessibility: entire app missing Semantics labels |
| FIX-14 | mobile | Low | Home grid: Profile tile redundant + empty slot |
| FIX-15 | data | Low | Test/seed data cleanup in production DB |

---

## FIX-01 — Mobile: Guest pass expiry not reflected in UI (Critical)

**Bugs covered:** Gate Bug 3 (expired passes show Active), Gate Bug 5 (no Expired state for unscanned-lapsed passes), Home Bug 6 (guest pass badge count inaccurate)

**Root cause:**  
`GuestPassCard` in `gate_screen.dart:283` renders:
```dart
StatusChip(status: pass.isActive ? 'active' : pass.status)
```
`isActive` returns `false` once `validUntil` is past, but `pass.status` is still `'active'` from the DB (backend only updates to `EXPIRED` during a QR scan — not during list fetches). So expired-but-unscanned passes show green "Active" badge.

The home badge count (`activeGuestPasses`) queries `WHERE status = 'ACTIVE'` — same stale data problem.

**Files to change:**

### `mobile/lib/features/gate/providers/gate_provider.dart`
Add a `displayStatus` getter to the `GuestPass` model that derives the client-side expired state:
```dart
String get displayStatus {
  if (status == 'active' && DateTime.now().isAfter(validUntil)) return 'expired';
  return status;
}
```

### `mobile/lib/features/gate/screens/gate_screen.dart` (line ~283)
Change the StatusChip to use the new getter:
```dart
// Before:
StatusChip(status: pass.isActive ? 'active' : pass.status)

// After:
StatusChip(status: pass.displayStatus)
```

### `backend/src/guests/guests.service.ts` — `getMyPasses()`
When fetching the resident's passes, update stale `ACTIVE` passes that are past `validUntil` to `EXPIRED` so the badge count is accurate:
```ts
// After findMany, run a background update for any that should be EXPIRED:
await this.prisma.guestPass.updateMany({
  where: {
    userId,
    status: GuestPassStatus.ACTIVE,
    validUntil: { lt: now },
  },
  data: { status: GuestPassStatus.EXPIRED },
});
```
Run this before the findMany (or in parallel with it). This makes the badge count from `getDashboardSummary` accurate, since it also queries by `status: 'ACTIVE'`.

**Also update StatusChip color map** — ensure `'expired'` is mapped to a gray/neutral color (not green or red) in `mobile/lib/shared/widgets/status_chip.dart`.

---

## FIX-02 — Backend: Admin mark-paid creates no Payment record (Critical)

**Bugs covered:** Payments Bug 2 (5 of 9 payment history items show "Just Paid" with no date)

**Root cause:**  
`adminService.markBillPaid()` (`backend/src/admin/admin.service.ts:293`) only calls `prisma.bill.update({ data: { status: PAID } })`. It never creates a `Payment` record. The resident-facing bill response is built as `paidAt: b.payments[0]?.paidAt ?? null` — so bills marked paid via the admin dashboard have no payment record, and `paidAt` returns `null`.

The 5 entries showing "Just Paid" (no date) in the bug report are exactly the bills that were marked paid via the admin dashboard. The 4 entries showing a date were paid by the resident via the app (which DOES create a Payment record).

**File to change: `backend/src/admin/admin.service.ts`**

Replace the current `markBillPaid` (lines 293–305) with a `$transaction` version:
```ts
async markBillPaid(id: string, adminId?: string) {
  const bill = await this.prisma.bill.findUnique({ where: { id } });
  if (!bill) throw new NotFoundException(`Bill ${id} not found`);
  if (bill.status === BillStatus.PAID) return bill; // idempotent

  return this.prisma.$transaction([
    this.prisma.payment.create({
      data: {
        billId: id,
        userId: bill.userId,
        unitId: bill.unitId,
        amount: bill.amount,
        currency: bill.currency,
        method: 'BANK_TRANSFER',  // admin-initiated default
        status: 'COMPLETED',
        paidAt: new Date(),
        reference: `admin-manual-${id.slice(0, 8)}`,
      },
    }),
    this.prisma.bill.update({
      where: { id },
      data: { status: BillStatus.PAID },
      include: {
        user: { select: { id: true, name: true } },
        unit: { select: { id: true, number: true, building: true } },
      },
    }),
  ]).then(([, bill]) => bill);
}
```

**Note:** After deploying this fix, the 5 existing bills with missing `paidAt` will still show "Just Paid" unless a retroactive data migration is run (see FIX-15 for data tasks).

---

## FIX-03 — Admin: Create Bill form is unusable (Critical)

**Bugs covered:** Billing admin Bug 1 (form doesn't submit, silent failure), field name mismatch

**Root cause (two bugs):**
1. `residentId` and `unitId` are plain `<Input>` text fields with placeholder "resident-uuid" / "unit-uuid" — no user can type a valid UUID
2. The form field is named `residentId` but the backend DTO expects `userId` — even if a valid UUID were typed, the API would create a bill with `userId: undefined`

**Files to change:**

### `admin/src/app/billing/-schema/index.ts`
Rename `residentId` → `userId`:
```ts
export const createBillSchema = z.object({
  userId: z.string().min(1, 'Resident is required'),
  unitId: z.string().min(1, 'Unit is required'),
  type: z.enum(['MONTHLY_FEE', 'UTILITIES', 'MAINTENANCE_FEE', 'PARKING', 'OTHER']),
  amount: z.coerce.number().positive('Amount must be positive'),
  dueDate: z.string().min(1, 'Due date is required'),
  description: z.string().optional(),
})
```

### `admin/src/app/billing/index.tsx`
Replace the `residentId` and `unitId` `<Input>` fields with `<Select>` dropdowns.

Add imports at the top:
```tsx
import { useResidentList } from '@/app/residents/-components/list/service'
import { useUnitList } from '@/app/units/-components/list/service'
```

Inside `CreateBillButton`, fetch the lists:
```tsx
const { data: residentsData } = useResidentList({ take: 200 })
const { data: unitsData } = useUnitList({ take: 100 })
const residents = residentsData?.data ?? []
const units = unitsData?.data ?? []
```

Replace the `residentId` field:
```tsx
<FormField control={form.control} name="userId" render={({ field }) => (
  <FormItem>
    <FormLabel>Resident <span className="text-[var(--danger)]">*</span></FormLabel>
    <Select onValueChange={field.onChange} value={field.value}>
      <FormControl><SelectTrigger><SelectValue placeholder="Select resident" /></SelectTrigger></FormControl>
      <SelectContent>
        {residents.map((r) => (
          <SelectItem key={r.id} value={r.id}>{r.name} — {r.phone}</SelectItem>
        ))}
      </SelectContent>
    </Select>
    <FormMessage />
  </FormItem>
)} />
```

Replace the `unitId` field with the same pattern using `units.map((u) => ...)`.

Update `defaultValues` to use `userId: ''` instead of `residentId: ''`.

---

## FIX-04 — Mobile: ID Documents screen not implemented (Critical)

**Bugs covered:** Profile Bug 1 (ID Documents tap does nothing)

**Root cause:**  
`profile_screen.dart:107`: `onTap: () {}` — empty stub, no route, no screen.

**Files to change:**

### Create `mobile/lib/features/profile/screens/id_documents_screen.dart`
A screen that fetches and displays the resident's uploaded ID documents (front/back). Use the existing S3 presigned URL pattern already established for maintenance photo uploads.

Minimum viable screen:
- Shows a list of uploaded documents (id-front, id-back) if they exist
- Each document shows as a tappable thumbnail navigating to a fullscreen view
- An "Upload Document" button for each slot that calls `GET /uploads/presigned-url` then PUTs to S3
- If no documents uploaded: empty state with upload prompt

Since the backend already has `GET /uploads/my-documents` or similar (check `backend/src/uploads/uploads.service.ts` for the available endpoints), use that. If no list endpoint exists, you can derive document URLs from the known S3 key pattern `uploads/{userId}/id-front.jpg` and `uploads/{userId}/id-back.jpg`.

### `mobile/lib/features/profile/screens/profile_screen.dart` (line 107)
```dart
// Before:
onTap: () {},

// After:
onTap: () => context.push('/home/id-documents'),
```

### `mobile/lib/core/router/app_router.dart`
Add the route inside the `/home` shell:
```dart
GoRoute(
  path: '/home/id-documents',
  builder: (context, state) => const IdDocumentsScreen(),
),
```

---

## FIX-05 — Mobile: Payment history UX — tappable rows + bill detail missing paid date (High)

**Bugs covered:** Payments Bug 4 (history items not tappable), Payments Bug 3 (bill details never show payment date)

**Root cause:**  
`payment_history_screen.dart`: `ListTile` has no `onTap`. The identical item in the main payments list IS tappable, but the history list forgot to add navigation.  
`bill_detail_screen.dart`: Header card only shows due date (`'Due ${dateFmt.format(bill.dueDate)}'`). `bill.paidAt` is available in the model but never displayed.

**Files to change:**

### `mobile/lib/features/payments/screens/payment_history_screen.dart`
Add `onTap` to the `ListTile` for each item:
```dart
ListTile(
  onTap: () => context.push('/home/payments/${bill.id}'),
  // ... existing content ...
)
```

### `mobile/lib/features/payments/screens/bill_detail_screen.dart`
After the "Due [date]" text in the header card, add a paid date row for paid bills:
```dart
// After the due date Text widget, within the header card Column:
if (bill.status == BillStatus.paid && bill.paidAt != null)
  Text(
    'Paid on ${dateFmt.format(bill.paidAt!)}',
    style: TextStyle(
      color: Colors.white.withOpacity(0.8),
      fontSize: 14,
    ),
  ),
```

---

## FIX-06 — Mobile: Chat improvements — timestamps + close ticket (High)

**Bugs covered:** Chat Bug 4 (message timestamps no date), Chat Bug 5 (list date no year/relative), Chat Bug 8 (no way to close a conversation from the app)

**Root cause:**  
- `conversation_screen.dart:155`: `DateFormat('h:mm a')` — shows only time, no date for older messages  
- `chat_screen.dart:79`: `DateFormat('MMM d')` — shows "May 12" with no year  
- No close/resolve button exists anywhere in the mobile chat thread

**Files to change:**

### `mobile/lib/features/chat/screens/conversation_screen.dart`

**Timestamp fix (line ~155):** Replace the simple `DateFormat('h:mm a')` with a smart formatter:
```dart
String _formatMessageTime(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(dt.year, dt.month, dt.day);
  if (messageDay == today) {
    return DateFormat('h:mm a').format(dt);
  }
  return DateFormat('d MMM, h:mm a').format(dt);
}
```
Use `_formatMessageTime(message.createdAt)` instead of the current `timeFmt.format(...)`.

**Close ticket action:** Add a close action to the AppBar:
```dart
actions: [
  if (conv.status == 'open')
    TextButton(
      onPressed: () => _closeTicket(context, ref),
      child: const Text('Close', style: TextStyle(color: Colors.white70)),
    ),
],
```

Add `_closeTicket` method that:
1. Shows a confirmation dialog
2. Calls `PATCH /chat/conversations/{id}/close` (new backend endpoint — see backend addition below)
3. On success, navigates back to the chat list

### `mobile/lib/features/chat/screens/chat_screen.dart` (line ~79)

Replace `DateFormat('MMM d')` with a relative-smart formatter:
```dart
String _formatConvDate(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dtDay = DateTime(dt.year, dt.month, dt.day);
  if (dtDay == today) return DateFormat('h:mm a').format(dt);
  if (dt.year == now.year) return DateFormat('d MMM').format(dt);
  return DateFormat('d MMM y').format(dt);
}
```

### `backend/src/chat/chat.controller.ts`
Add a resident-accessible close endpoint:
```ts
@Patch('conversations/:id/close')
@ApiOperation({ summary: 'Resident closes their own conversation' })
closeConversation(@User() user: any, @Param('id') id: string) {
  const residentId = user.primaryUserId ?? user.id;
  return this.chatService.closeConversation(residentId, id);
}
```

### `backend/src/chat/chat.service.ts`
Add the `closeConversation` method:
```ts
async closeConversation(residentId: string, conversationId: string) {
  const conv = await this.prisma.conversation.findUnique({ where: { id: conversationId } });
  if (!conv) throw new NotFoundException('Conversation not found');
  if (conv.residentId !== residentId) throw new ForbiddenException();
  if (conv.status === ConversationStatus.CLOSED) return mapConversation(conv);

  const updated = await this.prisma.conversation.update({
    where: { id: conversationId },
    data: { status: ConversationStatus.CLOSED, updatedAt: new Date() },
  });
  return mapConversation(updated);
}
```

### `mobile/lib/features/chat/providers/chat_provider.dart`
Add a `closeConversation` method to `ConversationDetailNotifier`:
```dart
Future<void> close() async {
  final dio = ref.read(dioProvider);
  await dio.patch('/chat/conversations/$arg/close');
  ref.invalidate(conversationDetailProvider(arg));
  ref.invalidate(conversationsProvider);
}
```

---

## FIX-07 — Admin: Wire Edit stubs for Residents and Announcements (High)

**Bugs covered:** Residents Bug 2/3 (row click nothing, edit not accessible), Announcements Bug 1 (no edit)

**Root cause:**  
- `admin/src/app/residents/-components/list/table.tsx`: The `Edit` dropdown item renders `<Pencil />` but has no `onClick` handler  
- `admin/src/app/announcements/index.tsx:136`: Edit button has no `onClick`  

**Files to change:**

### `admin/src/app/residents/-components/list/table.tsx`
Add a local `useState` for `editingResident` and an `EditResidentDialog` component.

The existing `useUpdateResident(id)` mutation in `service.ts` is already implemented. Wire it:

```tsx
// In the table component, add state:
const [editingResident, setEditingResident] = useState<Resident | null>(null)

// In the Edit dropdown item:
<DropdownMenuItem onClick={() => setEditingResident(row.original)}>
  <Pencil className="h-4 w-4" /> Edit
</DropdownMenuItem>

// Below the table, add the dialog:
{editingResident && (
  <EditResidentDialog
    resident={editingResident}
    onClose={() => setEditingResident(null)}
  />
)}
```

Create an `EditResidentDialog` component (in the same file or a new `edit-dialog/index.tsx`) with fields for name, phone, email, and a status toggle. On submit, call `useUpdateResident(resident.id)`.

### `admin/src/app/announcements/index.tsx`
Add local state for the announcement being edited and an edit dialog.

Import or create `useUpdateAnnouncement` in `announcements/-components/service.ts`:
```ts
export function useUpdateAnnouncement(id: string) {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (payload: Partial<AnnouncementValues>) => {
      const { data } = await api.patch(`/admin/announcements/${id}`, payload)
      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: queryKeys.announcements.all })
      toast.success('Announcement updated')
    },
    onError: () => toast.error('Failed to update announcement'),
  })
}
```

In `AnnouncementCard`, wire the Edit button:
```tsx
// Add to AnnouncementCard props:
onEdit: (a: Announcement) => void

// In the button:
<Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => onEdit(announcement)}>
  <Pencil className="h-3.5 w-3.5" />
</Button>
```

In `AnnouncementsPage`, add `useState<Announcement | null>` for `editingAnnouncement` and render an edit dialog (reuse the `CreateAnnouncementDialog` form fields pre-populated).

**Also check backend:** Verify `PATCH /admin/announcements/:id` exists in `admin.controller.ts`. If not, add it.

---

## FIX-08 — Backend: Filter expired announcements from all queries (High)

**Bugs covered:** Home Bug 3 (stale announcements visible), Home Bug 2 (preview shows expired/test data since test data has earliest publishedAt after filtering)

**Root cause:**  
No query that fetches announcements filters by `expiresAt`. The `Emergency: Water Shutoff Tonight` announcement (Apr 30, event same day) and `Pool Maintenance — May 3rd` (event May 3) are still showing on May 17 with IMPORTANT badge.

**Files to change:**

### `backend/src/resident/resident.service.ts` — `getDashboardSummary()` (line ~32)
Add expiry filter:
```ts
this.prisma.announcement.findMany({
  where: {
    deletedAt: null,
    OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
  },
  orderBy: [{ isImportant: 'desc' }, { publishedAt: 'desc' }],
  take: 5,
}),
```
Also sort important announcements first, so the home preview prioritizes them.

### `backend/src/resident/resident.service.ts` — `getAnnouncements()` (wherever the full list is served)
Add the same expiry filter. Find the method that serves `GET /announcements` for residents and add:
```ts
where: {
  deletedAt: null,
  OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
},
```

### `backend/src/admin/admin.service.ts` — admin announcements list
The admin list should STILL show expired announcements (for management), but mark them visually. No backend filter needed for admin — handle display client-side with an "Expired" badge in the admin UI when `expiresAt < now`.

---

## FIX-09 — Mobile: Pay Bills tile should switch tab, not push stack (Medium)

**Bugs covered:** Payments Bug 6 ("Pay Bills" home tile opens stack screen with back arrow)

**Root cause:**  
`_QuickAction` widget always uses `context.push(route)`. For Pay Bills (route `/home/payments`), this pushes a new screen ON TOP of Home instead of switching the bottom navigation tab. The bottom nav still shows "Home" as active and a Back arrow appears.

**File to change: `mobile/lib/features/home/screens/home_screen.dart`**

The cleanest fix is to modify `_QuickAction` to accept an optional navigation callback override:
```dart
class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.labelKey,
    required this.route,
    required this.gradient,
    this.badgeAsync = 0,
    this.badgeDanger = false,
    this.onTap,  // ← add optional override
  });
  final VoidCallback? onTap;  // ← add field
  ...
  // In build():
  onTap: () => onTap != null ? onTap!() : context.push(route),
```

Then for the Pay Bills tile, pass a tab-switching callback:
```dart
_QuickAction(
  icon: Icons.receipt_long_rounded,
  labelKey: 'home.pay_bills',
  route: '/home/payments',
  gradient: AppColors.goldGradient,
  onTap: () => context.go('/home/payments'),  // go() switches tab
  ...
),
```

`context.go()` with an absolute path triggers GoRouter's tab navigation (the shell route switches to the Payments tab) instead of pushing a new screen on the Home stack.

Apply the same fix to any other tiles where the destination is a main tab (Maintenance → `/home/maintenance`, etc.) if they also have dedicated bottom nav tabs.

---

## FIX-10 — Mobile: Gate screen UX — duplicate button + QR scrolls off (Medium)

**Bugs covered:** Gate Bug 2 (two buttons that do the same thing), Gate Bug 6 (QR scrolls off screen)

**Root cause:**  
`gate_screen.dart`: AppBar `actions` has an `IconButton` (line ~26) AND the section title row has a `TextButton.icon` (line ~113). Both navigate to `/home/gate/create`.  
The entire screen content is in a single `SingleChildScrollView` — QR card at top, passes list below. With many passes, the QR scrolls out of view.

**File to change: `mobile/lib/features/gate/screens/gate_screen.dart`**

**Remove duplicate button:** Remove the AppBar `actions` block entirely (lines ~24-30). Keep only the `TextButton.icon` next to the "Guest Passes" section title.

**Pin QR card above scroll:** Convert the body to a `Column` with a fixed-height QR section (non-scrollable) and a separate `Expanded` + `ListView` for passes:
```dart
body: Column(
  children: [
    // Non-scrollable QR section (fixed at top)
    _QrSection(myQrAsync: myQrAsync, isDark: isDark),
    // Divider or SizedBox
    const SizedBox(height: 8),
    // Scrollable passes section
    Expanded(
      child: _GuestPassesList(passesAsync: passesAsync, isDark: isDark),
    ),
  ],
),
```

Move the QR card widget into `_QrSection` and the passes list (including the section header + "+ New Pass" button) into `_GuestPassesList`.

---

## FIX-11 — Admin: Improve error feedback for Create Resident / Create Bill conflicts (Medium)

**Bugs covered:** Residents Bug 1 (409 conflict shows generic "Failed to create resident"), Create Bill failure silent

**Root cause:**  
Both `useCreateResident` and `useCreateBill` use `onError: () => toast.error('Failed to ...')` — they don't extract the server's error message. A 409 from the backend contains `{ "message": "Phone number already in use" }` but this is discarded.

**Files to change:**

### `admin/src/app/residents/-components/list/service.ts` (line ~29)
```ts
onError: (error: any) => {
  const msg = error?.response?.data?.message
  toast.error(typeof msg === 'string' ? msg : 'Failed to create resident')
},
```

### `admin/src/app/billing/-components/service.ts` (line ~49)
```ts
onError: (error: any) => {
  const msg = error?.response?.data?.message
  toast.error(typeof msg === 'string' ? msg : 'Failed to create bill')
},
```

Apply the same pattern to any other `onError` handler in the admin that discards the server error detail.

---

## FIX-12 — Mobile: Home guest pass badge count stale (Medium)

**Bugs covered:** Home Bug 6 (Guest Pass badge shows 3 when there are 4+ active passes)

**Root cause:**  
`getDashboardSummary` counts `WHERE status = 'ACTIVE'` for guest passes. Expired passes remain `ACTIVE` in the DB until they're scanned. The badge shows a stale count.

**This is fixed as a side effect of FIX-01.** When `getMyPasses` runs the `updateMany` to flip expired passes to `EXPIRED`, subsequent dashboard summary calls will return the correct count. No additional change needed if FIX-01 is implemented.

However: if `getDashboardSummary` is called before the first `getMyPasses` (e.g., on home screen load without visiting the Gate screen), the count could still be stale. To fully fix, also add the same expiry update in `getDashboardSummary`:

### `backend/src/resident/resident.service.ts` — `getDashboardSummary()` (line ~27)
Before the `Promise.all`, add:
```ts
await this.prisma.guestPass.updateMany({
  where: { userId, status: 'ACTIVE', validUntil: { lt: now } },
  data: { status: 'EXPIRED' },
});
```

---

## FIX-13 — Mobile: Add accessibility Semantics labels (Low)

**Bugs covered:** Profile Bug (OTP fields no labels), Home Bug 1/5 (bell no label, badge merged into tile label), Payments (history button no label), Gate Bug 1/7 (header button, form fields), Chat Bug 1/2/3 (refresh, send, input no labels)

**Root cause:**  
The entire mobile app has **zero** `Semantics()` widgets. The Flutter framework provides no automatic content-desc for `GestureDetector`, `Container`, or custom widgets. Every interactive element that isn't a built-in `TextField`/`Button` needs an explicit `Semantics` wrapper.

**Files to change (in priority order):**

### `mobile/lib/features/home/screens/home_screen.dart`

**Notification bell (line ~111):** Wrap GestureDetector:
```dart
Semantics(
  label: 'home.notifications'.tr(),
  button: true,
  child: GestureDetector(
    onTap: () => _showNotifications(context, ref),
    child: Container(/* existing */),
  ),
),
```

**Service tile badge:** In `_QuickAction.build()`, wrap the badge `Container` in:
```dart
Semantics(
  label: '$badgeAsync pending',
  child: Container(/* badge */),
)
```
And add `excludeSemantics: true` to prevent the badge text from being merged into the tile label. Also wrap the entire tile in `Semantics(label: labelKey.tr(), button: true)`.

### `mobile/lib/features/chat/screens/chat_screen.dart`
Wrap the `IconButton` (refresh) in `Semantics(label: 'Refresh conversations', button: true)`, or add `tooltip: 'Refresh'` which Flutter exposes as a11y text.

### `mobile/lib/features/chat/screens/conversation_screen.dart`
The send button (wherever it is) and the message input `TextField` need labels. For the `TextField`, add `semanticsLabel: 'Message input'` as a decoration property.

### `mobile/lib/features/payments/screens/payment_history_screen.dart`  
The history/clock `IconButton` in the AppBar: add `tooltip: 'Payment History'`.

### `mobile/lib/features/gate/screens/gate_screen.dart`
The AppBar `+` button (after FIX-10 removes it, this is moot). If any other unlabelled buttons remain, add tooltips.

### `mobile/lib/features/gate/screens/create_pass_screen.dart`
`TextFormField` widgets already have `labelText` which is read by screen readers when unfocused. Add `semanticsLabel` to the decoration for the date picker fields which use a custom `_DateField` widget:
```dart
Semantics(
  label: 'gate.from'.tr(),
  child: _DateField(/* existing */),
),
```

### `mobile/lib/features/auth/screens/otp_screen.dart`
Each of the 6 OTP digit fields needs a unique label. Find the OTP field widgets and add `Semantics(label: 'OTP digit ${i+1}', child: ...)` for each.

---

## FIX-14 — Mobile: Home services grid — Profile tile + empty slot (Low)

**Bugs covered:** Home Bug 7 (Profile tile duplicates bottom nav), Home Bug 8 (empty grid slot)

**Root cause:**  
8 tiles in a 3-column grid leaves 1 empty slot. The 8th tile is "Profile" — a destination already reachable via the bottom nav bar.

**File to change: `mobile/lib/features/home/screens/home_screen.dart`**

**Option A (recommended):** Replace the Profile tile with a more useful service. Candidates based on the app's features:
- "Documents" (→ `/home/id-documents`, now implemented by FIX-04)
- "Book Amenity" (→ `/home/amenities`)

Replacing Profile with Documents gives 8 tiles (3+3+2) which still has an empty slot. For a balanced layout, either:
- Go to 9 tiles (3×3) — add one more meaningful tile
- Or use `mainAxisAlignment: MainAxisAlignment.center` on the last row

**Simplest fix for now:** Remove the Profile tile entirely (7 tiles = 3+3+1 with two empty slots, but at least no redundant tile). Apply flex wrap or a 2-column last row.

Actually the cleanest fix is: Replace Profile with Documents tile (8 tiles, 3+3+2 layout). Accept the one empty slot for now — it's better than showing a redundant Profile tile.

```dart
// Replace this tile:
_QuickAction(
  icon: Icons.person_rounded,
  labelKey: 'home.profile',
  route: '/home/profile',
  gradient: ...,
),

// With:
_QuickAction(
  icon: Icons.badge_outlined,
  labelKey: 'home.documents',
  route: '/home/id-documents',
  gradient: const LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
  ),
),
```

Add `'home.documents': 'Documents'` (and Arabic equivalent) to the localization files.

---

## FIX-15 — Data: Test/seed data cleanup (Low — Operational)

**Bugs covered:** Gate Bug 4/8 (duplicate/garbage passes), Payments Bug 5/7 (inconsistent naming, test bill), Home Bug 2/4 (garbled announcement preview), Chat observation (test response)

**Root cause:**  
Test/seed data was created during development and never purged from the production database.

**Required DB operations (run against production RDS):**

### Guest passes to delete:
```sql
DELETE FROM "GuestPass"
WHERE "guestName" IN ('Test', 'Review Test Guest', 'asaS', 'asaSAsSasa', 'Egegg', 'Demo Guest', 'Test Guest', 'Debug Test')
  AND "userId" = (SELECT id FROM "User" WHERE phone = '<Ahmad-Al-Safa-phone>');
```
Verify the UUIDs before deleting. Run `SELECT id, "guestName", status, "validUntil" FROM "GuestPass" ORDER BY "createdAt" DESC LIMIT 20` first.

### Test bill to delete:
```sql
-- Soft delete (preserves referential integrity):
UPDATE "Bill"
SET "deletedAt" = NOW()
WHERE description LIKE '%test%' OR title LIKE 'Review test%';
```
Verify: `SELECT id, type, amount, "dueDate", status FROM "Bill" WHERE description LIKE '%test%'`.

### Test announcement to delete:
```sql
UPDATE "Announcement"
SET "deletedAt" = NOW()
WHERE title = 'T' AND body = 'B';
```

### Test data in messages (manual admin action):
The "billing" conversation contains a support reply that says "your problem". This must be deleted or corrected via the admin dashboard Conversations panel — admin can send a correction reply. The fake message itself can be deleted via direct DB update if needed.

### Bill naming normalization (Payments Bug 5):
Bills with generic names ("Utilities", "Parking Fee") vs. bills with period names ("Utilities — April 2026") is a data entry inconsistency, not a code bug. The admin should update bill descriptions when creating them. No code change needed.

### Retroactive paidAt for admin-paid bills (supplements FIX-02):
After deploying FIX-02, existing bills that were marked paid via the admin dashboard still have no Payment record. To backfill:
```sql
-- Check which paid bills have no payment records:
SELECT b.id, b.type, b."dueDate", b."userId", b."unitId", b.amount, b.currency
FROM "Bill" b
LEFT JOIN "Payment" p ON p."billId" = b.id
WHERE b.status = 'PAID' AND p.id IS NULL AND b."deletedAt" IS NULL;

-- For each found, insert a Payment record manually:
INSERT INTO "Payment" ("id", "billId", "userId", "unitId", amount, currency, method, status, "paidAt", reference, "createdAt", "updatedAt")
VALUES (gen_random_uuid(), '<billId>', '<userId>', '<unitId>', <amount>, 'IQD', 'BANK_TRANSFER', 'COMPLETED', NOW(), 'admin-backfill', NOW(), NOW());
```
Run this for each of the 5 affected bills identified in the payment history report.

---

## Execution Order

```
Phase 1 — Critical (deploy as one PR)
  FIX-01  Guest pass expiry display
  FIX-02  Admin mark-paid Payment record
  FIX-03  Create Bill form overhaul
  FIX-04  ID Documents screen

Phase 2 — High (deploy as one PR)
  FIX-05  Payment history tappable + bill paid date
  FIX-06  Chat timestamps + close ticket
  FIX-07  Admin Edit stubs
  FIX-08  Announcement expiry filtering

Phase 3 — Medium (can batch or ship incrementally)
  FIX-09  Pay Bills tab navigation
  FIX-10  Gate UX cleanup
  FIX-11  Admin error messages
  FIX-12  Badge count (resolved by FIX-01 if both in same deploy)

Phase 4 — Polish
  FIX-13  Accessibility Semantics
  FIX-14  Home grid cleanup
  FIX-15  Data cleanup (can run anytime, independent of code)
```

---

## Summary

| Phase | Tasks | Bugs Fixed | Files Changed |
|---|---|---|---|
| 1 — Critical | FIX-01 to 04 | 8 critical bugs | ~7 files |
| 2 — High | FIX-05 to 08 | 9 high bugs | ~10 files |
| 3 — Medium | FIX-09 to 12 | 6 medium bugs | ~5 files |
| 4 — Polish | FIX-13 to 15 | 10 a11y + data bugs | ~8 files + SQL |
| **Total** | **15 groups** | **33 bugs covered** | |

**6 bugs from the report are incorrect** (features already work correctly in the current codebase) — do not spend time on these.
