# Backend Implementation Plan

**Agent**: Claude Code  
**Stack**: Node.js + NestJS + PostgreSQL (Prisma ORM)  
**Output dir**: /home/watson/.openclaw/workspace/al-safa-residence/backend/

---

## Read First
1. /home/watson/.openclaw/workspace/al-safa-residence/PROJECT.md
2. /home/watson/.openclaw/workspace/ai-project-factory/skills/nestjs-best-practices/SKILL.md
3. /home/watson/.openclaw/workspace/ai-project-factory/skills/nestjs-best-practices/references/patterns.md

---

## Infra Outputs (already provisioned)
- ECR: 590184057237.dkr.ecr.eu-central-1.amazonaws.com/al-safa-residence-api
- RDS endpoint: al-safa-residence-production.cb26say4c0pn.eu-central-1.rds.amazonaws.com:5432
- S3 bucket: al-safa-residence-uploads-590184057237
- Secrets ARN: arn:aws:secretsmanager:eu-central-1:590184057237:secret:/al-safa-residence/production/app-3giW8l
- Region: eu-central-1

---

## What to Build

A production-ready NestJS API for Al-Safa Residence property management platform.

### Project Setup
```
backend/
├── src/
│   ├── main.ts
│   ├── app.module.ts
│   ├── common/           # Shared decorators, guards, pipes, interceptors
│   ├── config/           # Configuration module (env vars)
│   ├── auth/             # JWT auth module
│   ├── users/            # User management
│   ├── units/            # Unit management (multi-unit support)
│   ├── maintenance/      # Maintenance requests
│   ├── payments/         # Bill payments and dues
│   ├── announcements/    # Announcements
│   ├── guests/           # Guest QR codes
│   ├── notifications/    # Push notifications (FCM)
│   ├── uploads/          # File uploads (S3 presigned URLs)
│   └── health/           # Health check endpoint
├── prisma/
│   ├── schema.prisma
│   └── migrations/
├── Dockerfile
├── package.json
├── tsconfig.json
├── nest-cli.json
└── .env.example
```

### Roles
- `resident` — can manage their own units, submit maintenance, pay bills, manage guests
- `admin` — full access to all data
- `security` — can scan QR codes, view gate log, see visitor info

### API Endpoints

#### Auth (`/api/auth`)
- POST `/login` — email+password → JWT access + refresh tokens
- POST `/refresh` — refresh token → new access token
- POST `/logout` — invalidate refresh token
- GET `/me` — current user profile

#### Users (`/api/users`)
- GET `/` — list users (admin only)
- GET `/:id` — get user
- POST `/` — create user (admin only)
- PATCH `/:id` — update user
- DELETE `/:id` — soft delete (admin only)

#### Units (`/api/units`)
- GET `/` — list units (admin: all, resident: own)
- GET `/:id` — unit detail with specs + stats
- POST `/` — create unit (admin)
- PATCH `/:id` — update unit
- POST `/:id/assign` — assign resident to unit (admin)

#### Maintenance (`/api/maintenance`)
- GET `/` — list requests (admin: all, resident: own)
- GET `/:id` — request detail
- POST `/` — submit request (resident)
- PATCH `/:id/status` — update status (admin)
- POST `/:id/photos` — upload photos (presigned URL flow)

#### Payments (`/api/payments`)
- GET `/bills` — list bills (resident: own, admin: all)
- GET `/bills/:id` — bill detail
- POST `/bills/:id/pay` — mark as paid / initiate payment
- GET `/history` — payment history
- POST `/autopay` — configure autopay

#### Announcements (`/api/announcements`)
- GET `/` — list (all authenticated)
- GET `/:id` — detail
- POST `/` — create (admin)
- PATCH `/:id` — update (admin)
- DELETE `/:id` — soft delete (admin)

#### Guests (`/api/guests`)
- GET `/` — list my guest passes (resident)
- GET `/:id` — guest pass detail
- POST `/` — create guest pass → generate QR code
- DELETE `/:id` — revoke pass
- POST `/scan` — scan QR (security role only) → return resident + unit info
- GET `/log` — gate access log (security + admin)

#### Notifications (`/api/notifications`)
- POST `/register-token` — register FCM device token
- POST `/send` — send notification (admin/system)

#### Uploads (`/api/uploads`)
- POST `/presigned` — get presigned PUT URL for S3
- Accepts: `{ key: string, contentType: string }` → returns `{ url, fields }`

#### Health
- GET `/health` → `{ status: 'ok', timestamp, version }`

---

## Database Schema (Prisma)

```prisma
model User {
  id           String   @id @default(uuid())
  email        String   @unique
  name         String
  phone        String?
  passwordHash String
  role         Role     @default(RESIDENT)
  isActive     Boolean  @default(true)
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  deletedAt    DateTime?

  unitAssignments UnitAssignment[]
  maintenance     MaintenanceRequest[]
  bills           Bill[]
  guestPasses     GuestPass[]
  notifications   DeviceToken[]
  payments        Payment[]
}

enum Role {
  RESIDENT
  ADMIN
  SECURITY
}

model Unit {
  id          String  @id @default(uuid())
  number      String  @unique
  floor       Int
  building    String?
  type        String  // studio, 1br, 2br, 3br, penthouse
  area        Float   // sqm
  bedrooms    Int
  bathrooms   Int
  parkingSpot String?
  isActive    Boolean @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  assignments UnitAssignment[]
  maintenance MaintenanceRequest[]
  bills       Bill[]
}

model UnitAssignment {
  id        String   @id @default(uuid())
  userId    String
  unitId    String
  isPrimary Boolean  @default(false)
  startDate DateTime @default(now())
  endDate   DateTime?
  user      User     @relation(fields: [userId], references: [id])
  unit      Unit     @relation(fields: [unitId], references: [id])

  @@unique([userId, unitId])
}

model MaintenanceRequest {
  id          String            @id @default(uuid())
  userId      String
  unitId      String
  title       String
  description String
  category    MaintenanceCategory
  status      MaintenanceStatus @default(PENDING)
  priority    Priority          @default(NORMAL)
  photoUrls   String[]
  notes       String?
  createdAt   DateTime          @default(now())
  updatedAt   DateTime          @updatedAt
  resolvedAt  DateTime?

  user User @relation(fields: [userId], references: [id])
  unit Unit @relation(fields: [unitId], references: [id])
}

enum MaintenanceCategory {
  PLUMBING
  ELECTRICAL
  AC_HVAC
  CLEANING
  PEST_CONTROL
  APPLIANCE
  STRUCTURAL
  OTHER
}

enum MaintenanceStatus {
  PENDING
  IN_PROGRESS
  RESOLVED
  CANCELLED
}

enum Priority {
  LOW
  NORMAL
  HIGH
  URGENT
}

model Bill {
  id          String      @id @default(uuid())
  userId      String
  unitId      String
  type        BillType
  amount      Float
  currency    String      @default("IQD")
  dueDate     DateTime
  status      BillStatus  @default(PENDING)
  description String?
  createdAt   DateTime    @default(now())
  updatedAt   DateTime    @updatedAt
  payments    Payment[]

  user User @relation(fields: [userId], references: [id])
  unit Unit @relation(fields: [unitId], references: [id])
}

enum BillType {
  MONTHLY_FEE
  UTILITIES
  MAINTENANCE_FEE
  PARKING
  OTHER
}

enum BillStatus {
  PENDING
  PAID
  OVERDUE
  CANCELLED
}

model Payment {
  id        String        @id @default(uuid())
  billId    String
  userId    String
  amount    Float
  currency  String        @default("IQD")
  method    PaymentMethod
  status    PaymentStatus @default(PENDING)
  reference String?
  paidAt    DateTime?
  createdAt DateTime      @default(now())

  bill Bill @relation(fields: [billId], references: [id])
  user User @relation(fields: [userId], references: [id])
}

enum PaymentMethod {
  CASH
  BANK_TRANSFER
  CARD
  ONLINE
}

enum PaymentStatus {
  PENDING
  COMPLETED
  FAILED
  REFUNDED
}

model Announcement {
  id          String   @id @default(uuid())
  title       String
  body        String
  isImportant Boolean  @default(false)
  publishedAt DateTime @default(now())
  expiresAt   DateTime?
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  deletedAt   DateTime?
}

model GuestPass {
  id          String          @id @default(uuid())
  userId      String
  guestName   String
  guestPhone  String?
  guestId     String?         // national ID
  purpose     String?
  qrCode      String          @unique // UUID used in QR
  status      GuestPassStatus @default(ACTIVE)
  validFrom   DateTime        @default(now())
  validUntil  DateTime?
  usedAt      DateTime?
  createdAt   DateTime        @default(now())

  user     User       @relation(fields: [userId], references: [id])
  gateLog  GateLog[]
}

enum GuestPassStatus {
  ACTIVE
  USED
  EXPIRED
  REVOKED
}

model GateLog {
  id          String   @id @default(uuid())
  guestPassId String
  scannedById String   // security user ID
  result      String   // APPROVED, DENIED, EXPIRED
  notes       String?
  scannedAt   DateTime @default(now())

  guestPass GuestPass @relation(fields: [guestPassId], references: [id])
}

model DeviceToken {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  platform  String   // ios, android
  createdAt DateTime @default(now())

  user User @relation(fields: [userId], references: [id])
}

model RefreshToken {
  id        String   @id @default(uuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())
}
```

---

## Technical Requirements

### Environment Variables (.env.example)
```
DATABASE_URL=postgresql://alsafa_admin:password@localhost:5432/alsafa_production
JWT_ACCESS_SECRET=your-access-secret
JWT_REFRESH_SECRET=your-refresh-secret
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
AWS_REGION=eu-central-1
AWS_S3_BUCKET=al-safa-residence-uploads-590184057237
FCM_SERVER_KEY=
PORT=3000
NODE_ENV=production
```

### Dockerfile
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
EXPOSE 3000
CMD ["node", "dist/main"]
```

### Key patterns (from nestjs-best-practices skill):
- All modules use NestJS module pattern with service + controller + DTOs
- Zod for validation (or class-validator)
- Soft deletes with `deletedAt`
- JWT guard on all routes except `/auth/login`, `/auth/refresh`, `/health`
- Role guard using `@Roles()` decorator
- Swagger decorators on all endpoints
- Prisma for all DB queries
- S3 presigned URLs for uploads (never stream files through the API)
- QR code generation using `qrcode` npm package

---

## Acceptance Criteria
- [ ] `npm run build` succeeds with no errors
- [ ] `npm run start:dev` starts without errors
- [ ] All endpoints listed above exist
- [ ] Prisma schema validates (`npx prisma validate`)
- [ ] Health endpoint returns 200
- [ ] Auth flow works (login → JWT → protected route)
- [ ] Dockerfile builds successfully
- [ ] .env.example has all required keys

---

## After completion:
1. Run: `npm run build` to verify
2. git add and commit: `feat(backend): implement NestJS API for Al-Safa Residence`
3. git push origin main
4. Write /home/watson/.openclaw/workspace/al-safa-residence/plans/backend-initial.results.md with Status: DONE
5. Run: `openclaw system event --text "Backend done: NestJS API built, all modules implemented, build passing" --mode now`
