import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:easy_localization/easy_localization.dart';
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
  bool _isSetupMode = false;
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
      setState(() { _isSetupMode = false; _isLoading = false; });
      await _verify();
    } else {
      setState(() { _isSetupMode = true; _isLoading = false; });
    }
  }

  Future<void> _verify() async {
    setState(() { _isLoading = true; _showPinFallback = false; });
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        setState(() { _isLoading = false; _showPinFallback = true; });
        return;
      }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'biometric.use_biometric_continue'.tr(),
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (authenticated && mounted) {
        await _goHome();
      } else if (mounted) {
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
      if (!canCheck) { await _skip(); return; }
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'biometric.biometric_description'.tr(),
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (authenticated && mounted) {
        final storage = ref.read(secureStorageProvider);
        await storage.setHasBiometricSetup();
        if (mounted) await _goHome();
      } else if (mounted) {
        await _skip();
      }
    } catch (_) {
      if (mounted) await _skip();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _skip() => _goHome();

  Future<void> _goHome() async {
    if (!mounted) return;
    final storage = ref.read(secureStorageProvider);
    final actorType = await storage.getActorType() ?? 'resident';
    if (!mounted) return;
    if (actorType == 'household_member') {
      context.go('/household-home');
    } else {
      context.go('/home');
    }
  }

  Future<void> _verifyPin() async {
    final pin = _pinCtrl.text.trim();
    if (pin == '1234') {
      if (mounted) await _goHome();
    } else {
      setState(() => _pinError = 'biometric.incorrect_pin'.tr());
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
              Text('biometric.verify_identity'.tr(), style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('biometric.use_biometric_continue'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),
              GoldButton(label: 'biometric.use_biometric'.tr(), icon: Icons.fingerprint_rounded, isLoading: _isLoading, onPressed: _verify),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() => _showPinFallback = true),
                child: Text('biometric.use_pin_instead'.tr()),
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
              Text('biometric.enter_pin'.tr(), style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('biometric.enter_4digit_pin'.tr(),
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
                  hintText: 'biometric.pin_hint'.tr(),
                  errorText: _pinError,
                ),
                onChanged: (v) {
                  if (_pinError != null) setState(() => _pinError = null);
                  if (v.length == 4) _verifyPin();
                },
              ),
              const SizedBox(height: 24),
              GoldButton(label: 'common.confirm'.tr(), icon: Icons.check_rounded, onPressed: _verifyPin),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _verify,
                child: Text('biometric.try_biometric_again'.tr()),
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
              Text('biometric.enable_quick_login'.tr(), style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('biometric.biometric_description'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                  textAlign: TextAlign.center),
              const SizedBox(height: 48),
              GoldButton(label: 'biometric.enable_biometric'.tr(), icon: Icons.fingerprint_rounded, isLoading: _isLoading, onPressed: _enableBiometric),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skip,
                child: Text('biometric.skip_for_now'.tr(), style: TextStyle(color: isDark ? AppColors.darkTextMuted : AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
