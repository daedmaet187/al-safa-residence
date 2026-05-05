# Plan: Household Members Feature

## Overview
Allow a primary resident to add sub-accounts (household members) linked to their unit. Each member gets their own phone+OTP login with enforced access tiers at the API level.

## Access Tiers

| Feature | Primary Resident | Full Access Member | Limited Member |
|---|---|---|---|
| Gate QR (own) | ✅ | ✅ | ✅ |
| Guest passes | ✅ | ✅ | ❌ |
| Maintenance requests | ✅ | ✅ | ❌ |
| Home services | ✅ | ✅ | ❌ |
| Announcements | ✅ | ✅ | ✅ |
| Unit info | ✅ | ✅ | ❌ |
| Own profile | ✅ | ✅ | ✅ |
| Bills / Payments | ✅ | ❌ | ❌ |

---

## Phase 1 — Backend

### 1. Prisma Schema Changes

Add to `schema.prisma`:

```prisma
model HouseholdMember {
  id           String             @id @default(uuid())
  primaryUserId String            // the resident who owns this unit
  phone        String             @unique
  name         String
  relationship String             // spouse, son, daughter, parent, other
  accessLevel  HouseholdAccess    @default(LIMITED)
  isActive     Boolean            @default(true)
  createdAt    DateTime           @default(now())
  updatedAt    DateTime           @updatedAt

  primaryUser  User               @relation(fields: [primaryUserId], references: [id])
  deviceTokens HouseholdDeviceToken[]
  guestPasses  GuestPass[]        // Full Access only

  @@map("household_members")
}

enum HouseholdAccess {
  FULL
  LIMITED
}
```

Also:
- Add `householdMembers HouseholdMember[]` relation to `User` model
- Add `HouseholdDeviceToken` model (same as DeviceToken but for household members)
- Add optional `householdMemberId` to `GuestPass`, `MaintenanceRequest` (so requests can be attributed)

### 2. Auth Changes (`src/auth/`)

- `/auth/login` already handles phone+OTP. Extend to also resolve `HouseholdMember` by phone.
- JWT payload: add `actorType: 'resident' | 'household_member'` and `actorId`, `accessLevel`, `primaryUserId`, `unitId`
- New guard: `HouseholdAccessGuard` — reads `accessLevel` from JWT, checks against required tier per endpoint

### 3. New Module: `src/household/`

Endpoints (primary resident only):
- `GET /household/members` — list my unit's household members
- `POST /household/members` — add a member (name, phone, relationship, accessLevel)
- `PATCH /household/members/:id` — edit name/relationship/accessLevel
- `DELETE /household/members/:id` — remove member (soft delete)

### 4. Resident Module — Access enforcement

Apply `HouseholdAccessGuard` to existing resident endpoints:

| Endpoint | Min required |
|---|---|
| `GET /resident/gate/my-qr` | LIMITED |
| `GET/POST /resident/gate/passes` | FULL |
| `GET /resident/maintenance*` | FULL |
| `GET /resident/units/my-unit` | FULL |
| `GET /resident/announcements` | LIMITED |
| `GET/PATCH /resident/profile` | LIMITED |
| `GET /resident/bills*` | PRIMARY_ONLY |
| `POST /resident/bills*/pay` | PRIMARY_ONLY |
| `GET /resident/dashboard/summary` | FULL |

### 5. DB Migration
- New migration: `add_household_members`

---

## Phase 2 — Mobile (Flutter)

### Profile menu
- Add "Household Members" tile between My Unit and Documents

### Household Members screen (`features/profile/household_members/`)
- List screen: member cards with avatar initials, name, relationship, access badge
- Add member sheet: name, phone, relationship dropdown, access level toggle
- Member detail screen: view + edit + remove

### Secondary member experience
- After phone+OTP login, if `actorType == household_member`:
  - Show simplified home screen: Gate Access, Submit Request (Full only), Announcements, Profile
  - Bottom nav: Home, Gate, Services (Full only), Profile
  - Hide bills, payments, unit management entirely
  - Show badge: "Villa 042 — Family Member"
  - Show note: "Some features are managed by the primary account holder."

### Auth provider
- Store `actorType` + `accessLevel` in secure storage
- Route to correct home screen based on `actorType`

---

## Phase 3 — Admin (React)

### Unit detail page
- Add "Household Members" section showing all members for that unit
- Columns: name, relationship, phone, access level, status, added date
- Admin can deactivate a household member (no add/edit — that's the resident's job)

---

## Implementation Order
1. Backend: schema + migration + auth changes + household module + access guards
2. Mobile: auth routing + simplified home screen + profile household screens  
3. Admin: unit detail household members section

---

## Files to create/modify

### Backend
- `prisma/schema.prisma` — add HouseholdMember model + enum
- `prisma/migrations/` — new migration
- `src/household/household.module.ts`
- `src/household/household.controller.ts`
- `src/household/household.service.ts`
- `src/household/dto/create-member.dto.ts`
- `src/household/dto/update-member.dto.ts`
- `src/auth/auth.service.ts` — extend login to resolve household members
- `src/auth/auth.module.ts` — register household module
- `src/auth/guards/household-access.guard.ts` — new guard
- `src/auth/dto/jwt-payload.dto.ts` — extend with actorType/accessLevel
- `src/resident/resident.controller.ts` — apply guards
- `src/app.module.ts` — register HouseholdModule

### Mobile
- `lib/features/profile/household_members/household_members_screen.dart`
- `lib/features/profile/household_members/add_member_sheet.dart`
- `lib/features/profile/household_members/member_detail_screen.dart`
- `lib/features/profile/household_members/household_provider.dart`
- `lib/features/home/home_screen.dart` — branch for household member
- `lib/features/auth/auth_provider.dart` — store actorType
- `lib/core/router.dart` — route based on actorType
- `lib/shared/models/household_member.dart`

### Admin
- `src/pages/units/UnitDetail.tsx` — add HouseholdMembers section (or new tab)
- `src/components/units/HouseholdMembersTable.tsx`
