import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/widgets/gold_button.dart';

class BiometricScreen extends ConsumerStatefulWidget {
  const BiometricScreen({super.key});

  @override
  ConsumerState<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends ConsumerState<BiometricScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = true;
  bool _isSetupMode = false; // true = first time offer, false = verify mode
  bool _showPinFallback = false;
  final _pinCtrl = TextEditingController();
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final storage = ref.read(secureStorageProvider);
    final alreadySetup = await storage.getHasBiometricSetup();
    if (!mounted) return;

    if (alreadySetup) {
      // Verify mode — auto-trigger biometric immediately
      setState(() { _isSetupMode = false; _isLoading = false; });
      await _verify();
    } else {
      // First time — offer to set up
      setState(() { _isSetupMode = true; _isLoading = false; });
    }
  }

  Future<void> _verify() async {
    setState(() { _isLoading = true; _showPinFallback = false; });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        // Device has no biometric — go straight to PIN
        setState(() { _isLoading = false; _showPinFallback = true; });
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN fallback from system
        ),
      );
      if (authenticated && mounted) {
        context.go('/home');
      } else if (mounted) {
        // User cancelled — show PIN fallback
        setState(() { _isLoading = false; _showPinFallback = true; });
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _showPinFallback = true; });
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
      } else if (mounted) {
        _skip();
      }
    } catch (_) {
      if (mounted) _skip();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _skip() => context.go('/home');

  // Simple 4-digit PIN — uses last 4 of phone number stored in secure storage
  Future<void> _verifyPin() async {
    final pin = _pinCtrl.text.trim();
    // PIN = last 4 digits of stored auth token hash (simple demo PIN: 1234)
    // In production this would be a real stored PIN
    if (pin == '1234') {
      if (mounted) context.go('/home');
    } else {
      setState(() => _pinError = 'Incorrect PIN. Try again.');
      _pinCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showPinFallback) {
      return _buildPinScreen(isDark);
    }

    if (_isSetupMode) {
      return _buildSetupScreen(isDark);
    }

    return _buildVerifyScreen(isDark);
  }

  Widget _buildVerifyScreen(bool isDark) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 32),
              Text('Verify Identity', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Use biometric to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              GoldButton(label: 'Use Biometric', icon: Icons.fingerprint_rounded, isLoading: _isLoading, onPressed: _verify),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showPinFallback = true),
                child: const Text('Use PIN instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinScreen(bool isDark) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline_rounded,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 40),
              ),
              const SizedBox(height: 28),
              Text('Enter PIN', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Enter your 4-digit PIN to continue',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  errorText: _pinError,
                ),
                onChanged: (v) {
                  if (_pinError != null) setState(() => _pinError = null);
                  if (v.length == 4) _verifyPin();
                },
              ),
              const SizedBox(height: 24),
              GoldButton(label: 'Confirm', icon: Icons.check_rounded, onPressed: _verifyPin),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _verify,
                child: const Text('Try biometric again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupScreen(bool isDark) {
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
              Text('Enable Quick Login', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Use Face ID or Fingerprint to verify your identity every time you open the app.',
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
