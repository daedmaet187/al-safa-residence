# Al-Safa Residence — Project Config

**Slug**: al-safa-residence  
**Description**: Digital property management platform enabling residents to pay dues, request maintenance, manage guest access, and communicate with security.  
**Purpose**: Consumer / PropTech  
**Audience**: Residents living inside Al-Safa managed compound  
**Generated**: 2026-04-29  

---

## Stack

| Layer | Technology |
|---|---|
| Backend | Node.js + NestJS |
| Admin dashboard | React 19 + Vite + TanStack Router + shadcn/ui + Tailwind CSS v4 |
| Mobile | Flutter + Riverpod (iOS + Android) |
| Database | PostgreSQL on AWS RDS (eu-central-1) |
| Infrastructure | AWS ECS Fargate + ECR + ALB + CloudFront + S3 |
| DNS | Cloudflare (stuff187.com zone) |
| IaC | OpenTofu |
| CI/CD | GitHub Actions |

---

## URLs

| Service | URL |
|---|---|
| Landing page | https://safa.stuff187.com |
| API | https://safa-api.stuff187.com |
| Admin dashboard | https://safa-admin.stuff187.com |

---

## Features

### Core
- Maintenance requests (with photo uploads)
- Guest QR code access for security gate
- Bill payments and dues management
- Unit dashboard with specs, stats, multi-unit support
- Announcements
- Push notifications (FCM / APNs)
- Gate access log (security guard view)
- Resident profile and document uploads (ID docs, etc.)

### Auth & Roles
- Roles: `resident`, `admin`, `security`
- JWT + refresh token flow
- Multi-unit support (resident can own/manage multiple units)

### File Storage
- S3 bucket + presigned URL pattern
- ID documents, maintenance photos

---

## Design Tokens

| Token | Value |
|---|---|
| Primary | `#1B3A6B` (Navy) |
| Secondary | `#2D5EA8` |
| Accent / Gold | `#C9A96E` |
| Gold gradient | `linear-gradient(135deg, #D4AF7A, #C9A96E, #B8924A)` |
| Background | `#F5F6F8` |
| Surface | `#FFFFFF` |
| Sidebar | `#0F1F3D` |
| Dark bg | `#0B0D10` |
| Text | `#111827` |
| Text muted | `#6B7280` |
| Success | `#16A34A` |
| Warning | `#D97706` |
| Danger | `#DC2626` |
| Typography | Inter |
| Dark mode | Required |

Design reference: `~/safa residence/AlSafa_Design 2.html`

---

## Infrastructure

| Setting | Value |
|---|---|
| AWS Account | 590184057237 |
| Region | eu-central-1 |
| Scale tier | Growth |
| CF Zone ID | 5b4e910343402099233564343a994556 |
| CF Account ID | c1f62f8a89987a2dd9a132ddb49fe96b |

---

## Skills

| Layer | Skill |
|---|---|
| Backend | `nestjs-best-practices` (see ai-project-factory/skills/nestjs-best-practices/) |
| Frontend (admin) | `hala-dashboard-skill` (React 19 + Vite + TanStack Router pattern) |
| Mobile | Flutter + Riverpod (follow hala-dashboard patterns adapted for Flutter) |

---

## Coding Agents

- All code: **Codex** (`openai/gpt-5.3-codex`)
- No Opus for code generation
- Ask human when in doubt

---

## Screen Inventory

### Mobile App (Resident)
- RA-A: Auth (splash, language, OTP, biometric, onboarding, multi-unit setup)
- RA-B: Home (dashboard, services menu, notifications)
- RA-C: Payments (bills, payment methods, receipts, history, autopay)
- RA-D: Gate (guest QR, guest passes)
- RA-E: Maintenance (requests, photos, tracking)
- RA-F: Community (announcements, rules)
- RA-G: Unit (specs, stats)
- RA-H: Profile (profile, documents)
- RA-I: Multi-unit (unit switcher)
- RA-J: System (settings, support)

### Admin Dashboard
- AP-1: Residents management
- AP-2: Units management
- AP-3: Billing & payments
- AP-4: Maintenance management
- AP-5: Gate/security management (Daman)
- AP-6: Announcements
- AP-7: Staff management
- AP-8: Reports & analytics

### Security Guard App
- GO-1: Guard login
- GO-2: QR scan results
- GO-3: Visitor log

---

## Secrets Reference

All secrets stored in AWS Secrets Manager at `/al-safa-residence/production/app`

| Secret key | Description |
|---|---|
| DATABASE_URL | PostgreSQL connection string |
| JWT_ACCESS_SECRET | JWT access token secret |
| JWT_REFRESH_SECRET | JWT refresh token secret |
| FCM_SERVER_KEY | Firebase Cloud Messaging key |
| S3_BUCKET_NAME | S3 bucket for file uploads |
| CLOUDFRONT_URL | CloudFront distribution URL |
