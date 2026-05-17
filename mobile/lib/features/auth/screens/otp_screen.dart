import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  static const int _maxAttempts = 5;
  static const int _cooldownSeconds = 60;

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = _cooldownSeconds);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) timer.cancel();
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    try {
      await ref.read(authProvider.notifier).sendOtp(phone: widget.phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully')),
      );
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: ${e.toString()}')),
      );
    }
  }

  Future<void> _verify() async {
    if (_otpCode.length != 6 || _isLocked) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).verifyOtp(
            phone: widget.phone,
            otp: _otpCode,
          );
      if (!mounted) return;
      context.go('/biometric');
    } catch (e) {
      if (!mounted) return;
      final newAttempts = _failedAttempts + 1;
      if (newAttempts >= _maxAttempts) {
        setState(() {
          _failedAttempts = newAttempts;
          _isLocked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too many failed attempts. Please request a new OTP.'),
            duration: Duration(seconds: 5),
          ),
        );
      } else {
        setState(() => _failedAttempts = newAttempts);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.invalid_otp'.tr(namedArgs: {'error': e.toString()})),
          ),
        );
      }
      for (final c in _controllers) c.clear();
      if (mounted) _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('auth.verification'.tr()),
        leading: BackButton(onPressed: () => context.go('/login')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryLight
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.sms_outlined,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 28,
                ),),
              const SizedBox(height: 24),
              Text('auth.enter_otp'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'auth.otp_sent_to'.tr(namedArgs: {'phone': widget.phone}),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    height: 60,
                    child: TextFormField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: Theme.of(context).textTheme.headlineSmall,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              width: 2),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 5) {
                          _focusNodes[i + 1].requestFocus();
                        }
                        if (value.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              if (_isLocked)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Account temporarily locked after 5 failed attempts. Please request a new OTP.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                GoldButton(
                  label: 'auth.verify'.tr(),
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _verify,
                ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _resendCooldown > 0 ? null : _resendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(_resendCooldown > 0
                      ? 'Resend code in ${_resendCooldown}s'
                      : 'auth.resend_code'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
