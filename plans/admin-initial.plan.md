# Admin Dashboard Implementation Plan

**Agent**: Claude Code  
**Stack**: React 19 + Vite + TanStack Router + TanStack Query + shadcn/ui + Tailwind CSS v4  
**Output dir**: /home/watson/.openclaw/workspace/al-safa-residence/admin/

---

## Read First
1. /home/watson/.openclaw/workspace/al-safa-residence/PROJECT.md
2. /home/watson/.openclaw/workspace/al-safa-residence/design-tokens.json
3. /home/watson/.openclaw/workspace/al-safa-residence/admin/src/index.css (already exists — design tokens)
4. /home/watson/.openclaw/workspace/ai-project-factory/skills/hala-dashboard-skill/SKILL.md (full pattern reference — FOLLOW THIS EXACTLY)
5. "/home/watson/safa residence/AlSafa_Design 2.html" — reference only for AP-* sections (admin panels)

---

## Design Reference
From the HTML file, focus on these sections:
- `#ap-residents` — resident management screens
- `#ap-units` — unit management
- `#ap-billing` — billing and payments
- `#ap-maintenance` — maintenance management
- `#ap-daman` — gate/security (Daman) management
- `#ap-messages` — announcements
- `#ap-staff` — staff management
- `#ap-reports` — reports and analytics

Enhance the designs — do not copy 1:1. Use the design tokens already in admin/src/index.css.

---

## What to Build

A full admin dashboard for Al-Safa Residence property management.

### Project Setup
Follow the hala-dashboard skill EXACTLY for:
- Project structure (`src/app/<module>/`)
- File naming (kebab-case, private files prefixed with `-`)
- Feature module anatomy (index.tsx, -types.ts, -schema/, -components/)
- TanStack Router file-based routing
- TanStack Query for all data fetching
- React Hook Form + Zod for all forms
- Axios instance at `src/lib/axios.ts`

### Scaffold (vite + react + typescript)
```
admin/
├── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json
├── biome.json
├── src/
│   ├── main.tsx
│   ├── app/
│   │   ├── login/
│   │   ├── dashboard/          # Overview stats
│   │   ├── residents/          # AP-1: Resident management
│   │   ├── units/              # AP-2: Unit management
│   │   ├── billing/            # AP-3: Billing & payments
│   │   ├── maintenance/        # AP-4: Maintenance requests
│   │   ├── gate/               # AP-5: Gate/security (Daman)
│   │   ├── announcements/      # AP-6: Announcements
│   │   ├── staff/              # AP-7: Staff management
│   │   └── reports/            # AP-8: Reports
│   ├── components/
│   │   ├── ui/                 # shadcn components
│   │   └── common/
│   ├── hooks/
│   ├── lib/
│   │   ├── axios.ts            # Axios instance pointing to safa-api.stuff187.com
│   │   └── query-client.ts
│   ├── routes/                 # TanStack Router file-based routes
│   └── types/
```

### API Base URL
```
https://safa-api.stuff187.com/api
```

### Pages to Build

#### Login (`/login`)
- Email + password form
- JWT stored in localStorage
- Redirect to dashboard on success

#### Dashboard (`/`)
- Stats cards: total residents, total units, pending maintenance, overdue bills
- Recent activity feed
- Quick links to each section

#### Residents (`/residents`)
- Table: name, email, phone, unit(s), role, status, joined date
- Search + filter by role/status
- Create resident modal (name, email, phone, role, assign unit)
- Edit resident (inline or modal)
- Deactivate/reactivate
- View resident detail with their units, bills, maintenance history

#### Units (`/units`)
- Table: number, floor, building, type, area, resident(s), status
- Search + filter by type/floor/building
- Create unit form (all specs)
- Edit unit
- Assign/unassign resident
- Unit detail: specs, current resident, maintenance history, bills

#### Billing (`/billing`)
- Tabs: Bills | Payments | Overdue
- Bills table: resident, unit, type, amount, due date, status
- Create bill (select resident+unit, type, amount, due date)
- Mark as paid
- Payment history table
- Overdue alerts

#### Maintenance (`/maintenance`)
- Table: title, resident, unit, category, priority, status, submitted date
- Filter by status/category/priority
- Detail view: description, photos, status timeline
- Update status (pending → in progress → resolved)
- Add admin notes

#### Gate / Daman (`/gate`)
- Active guest passes table: guest name, resident, unit, QR, valid until, status
- Gate log: scan timestamp, guest, result (approved/denied), security officer
- Revoke a guest pass
- Search by guest name or resident

#### Announcements (`/announcements`)
- List: title, date, important flag, expires
- Create announcement (title, body, important toggle, expiry date)
- Edit / delete
- Preview

#### Staff (`/staff`)
- Table: name, email, role (admin/security), status
- Create staff member
- Edit role
- Deactivate

#### Reports (`/reports`)
- Maintenance stats: by category, by status, avg resolution time
- Payment stats: collected this month, overdue total, by bill type
- Occupancy: units occupied vs vacant
- Gate activity: passes created, scans per day
- Export to CSV buttons

---

## Key Implementation Details

### Auth
- Store JWT in localStorage as `alsafa_admin_token`
- Axios interceptor to add `Authorization: Bearer <token>` header
- On 401 → clear token → redirect to `/login`

### Data Tables
Use TanStack Table v8 following the hala-dashboard skill pattern.
Every table needs: search, pagination, column sorting.

### Forms
React Hook Form + Zod. Follow exact pattern from hala-dashboard skill.

### Styling
- Use design tokens from `src/index.css` (already written)
- Sidebar: `--color-sidebar` (#0F1F3D navy)
- Primary: `--color-primary` (#1B3A6B)
- Accent/gold: `--color-accent` (#C9A96E) for highlights
- Dark mode support via `.dark` class

### Sidebar Navigation
Icons (Phosphor or Lucide) for each section. Active state with primary color highlight.

---

## Package.json dependencies
```json
{
  "dependencies": {
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@tanstack/react-router": "^1.0.0",
    "@tanstack/react-query": "^5.0.0",
    "@tanstack/react-table": "^8.0.0",
    "react-hook-form": "^7.0.0",
    "zod": "^3.0.0",
    "@hookform/resolvers": "^3.0.0",
    "axios": "^1.0.0",
    "sonner": "^1.0.0",
    "lucide-react": "^0.400.0",
    "date-fns": "^3.0.0",
    "clsx": "^2.0.0",
    "tailwind-merge": "^2.0.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.0.0",
    "vite": "^6.0.0",
    "typescript": "^5.0.0",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/vite": "^4.0.0",
    "@biomejs/biome": "^1.0.0"
  }
}
```

---

## Acceptance Criteria
- [ ] `npm install` succeeds
- [ ] `npm run build` succeeds with no errors
- [ ] `npm run dev` starts without errors
- [ ] All 8 main sections have working pages with real API integration
- [ ] Login flow works
- [ ] Tables have search + pagination
- [ ] Forms have validation (Zod)
- [ ] Sidebar navigation works
- [ ] Design tokens applied (navy sidebar, gold accents)
- [ ] Dark mode toggle works

---

## After completion:
1. Run: `npm run build` to verify
2. git add and commit: `feat(admin): implement React admin dashboard for Al-Safa Residence`
3. git push origin main
4. Write /home/watson/.openclaw/workspace/al-safa-residence/plans/admin-initial.results.md with Status: DONE
5. Run: `openclaw system event --text "Admin done: React dashboard built, all 8 sections implemented, build passing" --mode now`
