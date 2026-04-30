# Mobile App Implementation Plan

**Agent**: Claude Code  
**Stack**: Flutter + Riverpod + go_router (iOS + Android)  
**Output dir**: /home/watson/.openclaw/workspace/al-safa-residence/mobile/

---

## Read First
1. /home/watson/.openclaw/workspace/al-safa-residence/PROJECT.md
2. /home/watson/.openclaw/workspace/al-safa-residence/mobile/lib/core/theme/app_colors.dart (already exists)
3. /home/watson/.openclaw/workspace/al-safa-residence/mobile/lib/core/theme/app_theme.dart (already exists)
4. /home/watson/.openclaw/workspace/ai-project-factory/skills/hala-dashboard-skill/SKILL.md (adapt patterns for Flutter)
5. "/home/watson/safa residence/AlSafa_Design 2.html" — reference for RA-* sections (resident app) and GO-* sections (security guard)

---

## Design Reference
From the HTML file focus on:
- `#ra-auth` — splash, login, OTP, biometric, onboarding
- `#ra-home` — home dashboard
- `#ra-payments` — bills and payments
- `#ra-gate` — guest QR codes
- `#ra-maintenance` — maintenance requests
- `#ra-community` — announcements
- `#ra-unit` — unit details
- `#ra-profile` — profile screen
- `#ra-multiunit` — multi-unit switcher
- `#go-auth`, `#go-results`, `#go-visitor` — security guard app

Enhance the designs — do not copy 1:1. Use AppColors from the theme file already created.

---

## What to Build

A Flutter mobile app for Al-Safa Residence residents, with a security guard mode.

### Project Structure
```
mobile/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/              # Already exists (app_colors.dart, app_theme.dart)
│   │   ├── router/             # go_router setup
│   │   ├── network/            # Dio HTTP client
│   │   └── storage/            # flutter_secure_storage
│   ├── features/
│   │   ├── auth/               # Login, OTP, biometric
│   │   ├── home/               # Home dashboard
│   │   ├── payments/           # Bills + payments
│   │   ├── gate/               # Guest QR codes
│   │   ├── maintenance/        # Maintenance requests
│   │   ├── community/          # Announcements
│   │   ├── unit/               # Unit details
│   │   ├── profile/            # Profile + documents
│   │   └── security/           # Security guard screens
│   └── shared/
│       ├── widgets/            # Shared UI components
│       └── models/             # Shared data models
```

### API Base URL
```
https://safa-api.stuff187.com/api
```

### Screens to Build

#### Auth Flow
- Splash screen (logo + gold gradient animation)
- Login: email + password
- OTP verification screen (6-digit code UI)
- Biometric setup prompt
- Onboarding tour (3 slides): key features
- Multi-unit prompt: if user has multiple units, pick primary

#### Home Dashboard
- Header: resident name + unit number pill (tappable for multi-unit switch)
- Quick action grid:
  - 🏠 My Unit
  - 🔧 Maintenance
  - 💰 Pay Bills
  - 👥 Guest Pass
  - 📢 Announcements
  - 🔔 Notifications
- Recent announcements preview (2-3 items)
- Active guest passes count badge
- Pending bill alert if overdue

#### Payments
- Bills list: amount, type, due date, status chip (pending/paid/overdue)
- Bill detail: breakdown + pay button
- Payment method selection (cash/bank transfer/card)
- Payment confirmation screen
- Payment history list
- Autopay toggle

#### Gate (Guest QR)
- My QR Code: full-screen QR for resident entry
- Guest Passes list
- Create guest pass form: guest name, phone, optional ID, valid date range
- QR code display for each pass (shareable)
- Revoke pass swipe action

#### Maintenance
- Requests list with status chips
- Create request: title, category picker, description, photo upload (camera/gallery)
- Request detail: status timeline, admin notes
- Status indicators: pending (orange), in-progress (blue), resolved (green)

#### Community (Announcements)
- Announcements feed: important ones at top with gold accent border
- Announcement detail: full text
- Community rules section (static)

#### Unit Dashboard
- Unit specs: number, floor, type, area, bedrooms, bathrooms, parking
- Stats: months in residence, total paid, open maintenance requests
- Documents: lease agreement (placeholder), unit photos

#### Profile
- Avatar with initials
- Name, email, phone (editable)
- Upload ID documents
- Change password
- Notification preferences
- Logout

#### Multi-Unit Switcher
- Bottom sheet or full screen
- List of units with address + type
- Select to switch active unit context

#### Security Guard App
- Separate login flow (security role)
- QR Scanner screen: large scan area, flash toggle
- Scan result: APPROVED (green) / DENIED (red) / EXPIRED (amber)
  - Show: guest name, resident name, unit, valid until
- Visitor log: scrollable list of recent scans

---

## Technical Requirements

### pubspec.yaml dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  go_router: ^13.0.0
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  shared_preferences: ^2.2.0
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.0.0          # QR scanner
  image_picker: ^1.0.0
  local_auth: ^2.2.0              # biometric
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
  flutter_animate: ^4.5.0
  intl: ^0.19.0
  cached_network_image: ^3.3.0
  permission_handler: ^11.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.4.0
  json_serializable: ^6.7.0
```

### State Management
Use Riverpod with code generation (`@riverpod` annotation).
Each feature has its own provider file following the pattern:
```dart
@riverpod
class MaintenanceRequests extends _$MaintenanceRequests {
  @override
  Future<List<MaintenanceRequest>> build() async {
    return ref.watch(maintenanceRepositoryProvider).getRequests();
  }
}
```

### HTTP Client
Dio instance with:
- Base URL: `https://safa-api.stuff187.com/api`
- Auth interceptor: adds `Authorization: Bearer <token>` from secure storage
- 401 interceptor: clear token + navigate to login

### Navigation (go_router)
```dart
Routes:
/ → splash
/login → LoginScreen
/onboarding → OnboardingScreen  
/home → HomeScreen (shell route with bottom nav)
/home/payments → PaymentsScreen
/home/gate → GateScreen
/home/maintenance → MaintenanceScreen
/home/community → CommunityScreen
/home/unit → UnitScreen
/home/profile → ProfileScreen
/security → SecurityHomeScreen (guard role)
/security/scan → QRScanScreen
/security/log → VisitorLogScreen
```

### Theme
Use the existing AppTheme.light and AppTheme.dark from app_theme.dart.
Support system dark mode by default.

---

## Acceptance Criteria
- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` shows no errors
- [ ] `flutter build apk --debug` succeeds
- [ ] All screens listed above are implemented
- [ ] Auth flow works end-to-end
- [ ] Navigation works between all screens
- [ ] API calls use the Dio client with auth interceptor
- [ ] Dark mode works
- [ ] QR code generation works for guest passes
- [ ] Camera/gallery picker works for maintenance photos

---

## After completion:
1. Run: `flutter analyze` and fix any errors
2. Run: `flutter build apk --debug` to verify
3. git add and commit: `feat(mobile): implement Flutter app for Al-Safa Residence`
4. git push origin main
5. Write /home/watson/.openclaw/workspace/al-safa-residence/plans/mobile-initial.results.md with Status: DONE
6. Run: `openclaw system event --text "Mobile done: Flutter app built, all screens implemented, apk build passing" --mode now`
