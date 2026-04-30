import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';
import '../providers/security_provider.dart';

class SecurityLoginScreen extends ConsumerStatefulWidget {
  const SecurityLoginScreen({super.key});

  @override
  ConsumerState<SecurityLoginScreen> createState() => _SecurityLoginScreenState();
}

class _SecurityLoginScreenState extends ConsumerState<SecurityLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(securityAuthProvider.notifier).sendOtp(
            phone: _phoneCtrl.text.trim(),
          );
      if (mounted) setState(() { _otpSent = true; });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('No account')
                ? 'No guard account found for this number.'
                : 'Error: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpCode.length != 6) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(securityAuthProvider.notifier).verifyOtp(
            phone: _phoneCtrl.text.trim(),
            otp: _otpCode,
          );
      if (mounted) context.go('/security');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid code. Try again.'), backgroundColor: AppColors.danger),
        );
        for (final c in _otpCtrls) c.clear();
        _otpFocusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sidebar, AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.security_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text('Security Guard Login',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Al-Safa Residence — Gate Access',
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14)),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _otpSent ? _buildOtpForm() : _buildPhoneForm(),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text('Resident login', style: TextStyle(color: Colors.white.withOpacity(0.65))),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phone Number', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '+964 770 123 4567',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (v) => v == null || v.trim().length < 7 ? 'Enter your phone number' : null,
          ),
          const SizedBox(height: 24),
          GoldButton(
            label: 'Send Code',
            icon: Icons.security_rounded,
            isLoading: _isLoading,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verification Code', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text('Sent to ${_phoneCtrl.text}', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => SizedBox(
            width: 44, height: 54,
            child: TextFormField(
              controller: _otpCtrls[i],
              focusNode: _otpFocusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: isDark ? AppColors.darkPrimary : AppColors.primary, width: 2),
                ),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) _otpFocusNodes[i + 1].requestFocus();
                if (v.isEmpty && i > 0) _otpFocusNodes[i - 1].requestFocus();
                if (_otpCode.length == 6) _verifyOtp();
              },
            ),
          )),
        ),
        const SizedBox(height: 24),
        GoldButton(
          label: 'Verify & Enter',
          icon: Icons.check_rounded,
          isLoading: _isLoading,
          onPressed: _verifyOtp,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() { _otpSent = false; for (final c in _otpCtrls) c.clear(); }),
            child: const Text('Change phone number'),
          ),
        ),
      ],
    );
  }
}
