import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/gold_button.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(phone: _phoneCtrl.text.trim());
      if (!mounted) return;
      context.push('/otp', extra: {'phone': _phoneCtrl.text.trim()});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('No account')
                ? 'No account found with this number. Contact your building admin.'
                : 'Something went wrong. Try again.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: const AppLogo(size: 72, dark: true))
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                'Welcome',
                style: Theme.of(context).textTheme.displaySmall,
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 6),
              Text(
                'Enter your phone number to receive a verification code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted),
              ).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+964 770 123 4567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                        if (v.trim().length < 7) return 'Enter a valid phone number';
                        return null;
                      },
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15),
                    const SizedBox(height: 24),
                    GoldButton(
                      label: 'Send Code',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Security staff? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.go('/security/login'),
                    child: const Text('Guard login'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
