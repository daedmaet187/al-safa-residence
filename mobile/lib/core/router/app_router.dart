import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/biometric_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/multi_unit_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/household_home_screen.dart';
import '../../features/payments/screens/payments_screen.dart';
import '../../features/payments/screens/bill_detail_screen.dart';
import '../../features/payments/screens/payment_method_screen.dart';
import '../../features/payments/screens/payment_history_screen.dart';
import '../../features/gate/screens/gate_screen.dart';
import '../../features/gate/screens/create_pass_screen.dart';
import '../../features/gate/screens/qr_display_screen.dart';
import '../../features/maintenance/screens/maintenance_screen.dart';
import '../../features/maintenance/screens/create_request_screen.dart';
import '../../features/maintenance/screens/request_detail_screen.dart';
import '../../features/community/screens/community_screen.dart';
import '../../features/community/screens/announcement_detail_screen.dart';
import '../../features/unit/screens/unit_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/support_screen.dart';
import '../../features/profile/screens/id_documents_screen.dart';
import '../../features/profile/household_members/household_members_screen.dart';
import '../../features/profile/household_members/member_detail_screen.dart';
import '../../features/security/screens/security_home_screen.dart';
import '../../features/security/screens/security_login_screen.dart';
import '../../features/security/screens/qr_scan_screen.dart';
import '../../features/security/screens/visitor_log_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/screens/conversation_screen.dart';
import '../../features/chat/screens/new_conversation_screen.dart';
import '../../features/amenities/screens/amenities_screen.dart';
import '../../features/amenities/screens/amenity_detail_screen.dart';
import '../../features/amenities/screens/my_bookings_screen.dart';
import '../storage/secure_storage.dart';
import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final storage = ref.read(secureStorageProvider);
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final token = await storage.getAuthToken();
      const publicRoutes = ['/login', '/onboarding', '/otp', '/biometric', '/security/login'];
      final loc = state.matchedLocation;
      final isPublic = loc == '/' || publicRoutes.any((r) => loc.startsWith(r));
      if (token == null && !isPublic) return '/login';
      return null;
    },
    routes: [
      // ── Splash ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth ─────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phone = extra['phone'] as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/biometric',
        builder: (context, state) => const BiometricScreen(),
      ),
      GoRoute(
        path: '/unit-setup',
        builder: (context, state) => const MultiUnitScreen(),
      ),

      // ── Household member home (simplified, no shell) ────────────────────────
      GoRoute(
        path: '/household-home',
        builder: (context, state) => const HouseholdHomeScreen(),
      ),

      // ── Home Shell (with bottom nav) ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) =>
            _HomeShell(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/home/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/home/gate',
            builder: (context, state) => const GateScreen(),
          ),
          GoRoute(
            path: '/home/maintenance',
            builder: (context, state) => const MaintenanceScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/home/support',
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: '/home/chat',
            builder: (context, state) => const ChatScreen(),
          ),
        ],
      ),

      // ── Amenities — static paths BEFORE parametric /:id ─────────────────────
      GoRoute(
        path: '/home/amenities',
        builder: (context, state) => const AmenitiesScreen(),
      ),
      GoRoute(
        path: '/home/amenities/my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/home/amenities/:id',
        builder: (context, state) =>
            AmenityDetailScreen(amenityId: state.pathParameters['id']!),
      ),

      // ── Home sub-routes (no shell) — static paths BEFORE parametric ────────
      GoRoute(
        path: '/home/payments/history',
        builder: (context, state) => const PaymentHistoryScreen(),
      ),
      GoRoute(
        path: '/home/payments/:id/pay',
        builder: (context, state) =>
            PaymentMethodScreen(billId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home/payments/:id',
        builder: (context, state) =>
            BillDetailScreen(billId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home/gate/create',
        builder: (context, state) => const CreatePassScreen(),
      ),
      GoRoute(
        path: '/home/gate/:id',
        builder: (context, state) =>
            QrDisplayScreen(passId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home/maintenance/create',
        builder: (context, state) => const CreateRequestScreen(),
      ),
      GoRoute(
        path: '/home/maintenance/:id',
        builder: (context, state) =>
            RequestDetailScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home/community',
        builder: (context, state) => const CommunityScreen(),
      ),
      GoRoute(
        path: '/home/community/:id',
        builder: (context, state) => AnnouncementDetailScreen(
            announcementId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/home/unit',
        builder: (context, state) => const UnitScreen(),
      ),
      GoRoute(
        path: '/home/unit-switcher',
        builder: (context, state) => const MultiUnitScreen(),
      ),

      // ── ID Documents ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/home/id-documents',
        builder: (context, state) => const IdDocumentsScreen(),
      ),

      // ── Household Members management (primary resident only) ─────────────────
      GoRoute(
        path: '/home/household-members',
        builder: (context, state) => const HouseholdMembersScreen(),
      ),
      GoRoute(
        path: '/home/household-members/:id',
        builder: (context, state) =>
            MemberDetailScreen(memberId: state.pathParameters['id']!),
      ),

      // ── Chat (static /new before parameterized /:id) ─────────────────────────
      GoRoute(
        path: '/home/chat/new',
        builder: (context, state) => const NewConversationScreen(),
      ),
      GoRoute(
        path: '/home/chat/:id',
        builder: (context, state) =>
            ConversationScreen(conversationId: state.pathParameters['id']!),
      ),

      // ── Security Guard ───────────────────────────────────────────────────────
      GoRoute(
        path: '/security/login',
        builder: (context, state) => const SecurityLoginScreen(),
      ),
      GoRoute(
        path: '/security',
        builder: (context, state) => const SecurityHomeScreen(),
      ),
      GoRoute(
        path: '/security/scan',
        builder: (context, state) => const QrScanScreen(),
      ),
      GoRoute(
        path: '/security/log',
        builder: (context, state) => const VisitorLogScreen(),
      ),
    ],
  );
});

// ── Bottom nav shell ─────────────────────────────────────────────────────────

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.child, required this.location});
  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border(
            top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 64,
            backgroundColor: Colors.transparent,
            indicatorColor: isDark
                ? AppColors.darkAccentLight
                : AppColors.accentLight,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) =>
                context.go(_routes[i]),
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Payments',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_outlined),
                selectedIcon: Icon(Icons.qr_code_2_rounded),
                label: 'Gate',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded),
                selectedIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _routes = [
    '/home',
    '/home/payments',
    '/home/gate',
    '/home/chat',
    '/home/profile',
  ];

  int get _selectedIndex {
    for (var i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i]) &&
          (_routes[i] != '/home' || location == '/home')) {
        return i;
      }
    }
    return 0;
  }
}
