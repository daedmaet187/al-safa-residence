import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../providers/auth_provider.dart';
import '../../../core/storage/secure_storage.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final authState = ref.read(authProvider);
    authState.when(
      data: (state) async {
        if (state.status == AuthStatus.authenticated) {
          if (state.user?.role == 'security' || state.user?.role == 'SECURITY') {
            context.go('/security');
          } else {
            context.go('/home');
          }
        } else {
          // Only show onboarding once; after that go straight to login
          final storage = ref.read(secureStorageProvider);
          final seen = await storage.getHasSeenOnboarding();
          if (!mounted) return;
          if (seen) {
            context.go('/login');
          } else {
            await storage.setHasSeenOnboarding();
            context.go('/onboarding');
          }
        }
      },
      loading: () => _navigate(),
      error: (_, __) => context.go('/login'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sidebar, AppColors.primary, Color(0xFF1E4080)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 100)
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                        begin: const Offset(0.7, 0.7),
                        duration: 600.ms,
                        curve: Curves.easeOutBack),
                const SizedBox(height: 28),
                const Text(
                  'Al-Safa Residence',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, duration: 500.ms),
                const SizedBox(height: 8),
                Text(
                  'Your home, managed.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 60),
                // Gold shimmer accent line
                Container(
                  width: 48,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms)
                    .scaleX(begin: 0, duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
