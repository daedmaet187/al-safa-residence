import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isChecking = false;

  Future<void> _enableBiometric() async {
    setState(() => _isChecking = true);
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        if (mounted) _skip();
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric login for quick access',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        context.go('/home');
      }
    } catch (_) {
      if (mounted) _skip();
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _skip() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentDark.withOpacity(0.4),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.7, 0.7), curve: Curves.easeOutBack),
              const SizedBox(height: 40),
              Text(
                'Enable Biometric Login',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 12),
              Text(
                'Use Face ID or Fingerprint to sign in quickly and securely next time.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted),
                textAlign: TextAlign.center,
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 48),
              GoldButton(
                label: 'Enable Biometric',
                icon: Icons.fingerprint_rounded,
                isLoading: _isChecking,
                onPressed: _enableBiometric,
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skip,
                child: Text(
                  'Skip for now',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted),
                ),
              ).animate(delay: 500.ms).fadeIn(),
            ],
          ),
        ),
      ),
    );
  }
}
