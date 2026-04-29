import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/gold_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      icon: Icons.home_rounded,
      title: 'Manage Your Home',
      body:
          'Track your unit details, service history, and documents all in one place.',
    ),
    _Slide(
      icon: Icons.qr_code_2_rounded,
      title: 'Smart Gate Access',
      body:
          'Generate guest passes and QR codes. Share access instantly with visitors.',
    ),
    _Slide(
      icon: Icons.receipt_long_rounded,
      title: 'Pay Bills Easily',
      body:
          'View upcoming bills, track payments, and manage your finances with ease.',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text('Skip',
                    style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _slides.length,
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: i == 0
                                ? AppColors.goldGradient
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: (i == 0
                                        ? AppColors.accentDark
                                        : AppColors.primary)
                                    .withOpacity(0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(slide.icon,
                              color: Colors.white, size: 56),
                        )
                            .animate(key: ValueKey(i))
                            .fadeIn(duration: 500.ms)
                            .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.easeOutBack),
                        const SizedBox(height: 40),
                        Text(
                          slide.title,
                          style:
                              Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('t$i'), delay: 150.ms)
                            .fadeIn()
                            .slideY(begin: 0.2),
                        const SizedBox(height: 12),
                        Text(
                          slide.body,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.textMuted),
                          textAlign: TextAlign.center,
                        )
                            .animate(key: ValueKey('b$i'), delay: 250.ms)
                            .fadeIn(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? (isDark ? AppColors.darkAccent : AppColors.accent)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GoldButton(
                label: _page == _slides.length - 1 ? 'Get Started' : 'Next',
                icon: _page == _slides.length - 1
                    ? Icons.check_rounded
                    : Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide({required this.icon, required this.title, required this.body});
}
