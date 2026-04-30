import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/gold_button.dart';

// This screen has two modes:
// 1. SETUP mode (first time after login) — offer to enable biometric
// 2. VERIFY mode — authenticate with biometric (if already set up)
class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = true;
  bool _isSetupMode = true; // true = offer setup, false = verify

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = ref.read(secureStorageProvider);
    final alreadySetup = await storage.getHasBiometricSetup();

    if (!mounted) return;

    if (alreadySetup) {
      // Verify mode — auto-trigger biometric
      setState(() { _isSetupMode = false; _isLoading = false; });
      await _verify();
    } else {
      // Setup mode — show offer screen
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _verify() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) { _skip(); return; }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to continue',
        options: const AuthenticationOptions(stickyAuth: true),
      );
      if (authenticated && mounted) context.go('/home');
    } catch (_) {
      if (mounted) _skip();
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) { _skip(); return; }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Enable biometric login for quick access',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated && mounted) {
        final storage = ref.read(secureStorageProvider);
        await storage.setHasBiometricSetup();
        if (mounted) context.go('/home');
      }
    } catch (_) {
      if (mounted) _skip();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isSetupMode) {
      // Verify mode — show simple screen with retry
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 56),
                ),
                const SizedBox(height: 32),
                Text('Verify Identity', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Use biometric to continue', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 40),
                GoldButton(label: 'Try Again', icon: Icons.fingerprint_rounded, onPressed: _verify),
                const SizedBox(height: 12),
                TextButton(onPressed: _skip, child: const Text('Use phone number instead')),
              ],
            ),
          ),
        ),
      );
    }

    // Setup mode
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.accentDark.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 12))],
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 40),
              Text('Enable Biometric Login', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Use Face ID or Fingerprint to sign in quickly next time.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              GoldButton(label: 'Enable Biometric', icon: Icons.fingerprint_rounded, isLoading: _isLoading, onPressed: _enableBiometric),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skip,
                child: Text('Skip for now', style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
