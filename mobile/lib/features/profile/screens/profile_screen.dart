import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildBody(context, ref, null, isDark),
        data: (user) => _buildBody(context, ref, user, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, user, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header — view only
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.surface,
              border: Border(
                bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user?.initials ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  user?.name ?? 'home.resident'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                if (user?.phone?.isNotEmpty == true)
                  Text(
                    user!.phone ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.textMuted),
                  ),
                if (user?.email?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    user!.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'profile.update_info_hint'.tr(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          _SectionTile(
            icon: Icons.badge_outlined,
            title: 'profile.id_documents'.tr(),
            onTap: () {},
          ),
          Consumer(builder: (ctx, ref, _) {
            final authState = ref.watch(authProvider).value;
            if (authState?.isResident != true) return const SizedBox.shrink();
            return _SectionTile(
              icon: Icons.people_alt_outlined,
              title: 'profile.household_members'.tr(),
              onTap: () => context.push('/home/household-members'),
            );
          }),
          
          // Language toggle
          _LanguageTile(),
          
          Consumer(builder: (ctx, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDarkNow = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(ctx) == Brightness.dark);
            return ListTile(
              leading: Icon(isDarkNow ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              title: Text(isDarkNow ? 'profile.switch_to_light'.tr() : 'profile.switch_to_dark'.tr(),
                  style: Theme.of(ctx).textTheme.titleSmall),
              trailing: Switch(
                value: isDarkNow,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggleDarkLight(),
                activeColor: AppColors.accent,
              ),
              onTap: () => ref.read(themeModeProvider.notifier).toggleDarkLight(),
            );
          }),
          _SectionTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'profile.chat_support'.tr(),
            onTap: () => context.push('/home/chat'),
          ),
          _SectionTile(
            icon: Icons.help_outline_rounded,
            title: 'profile.help_support'.tr(),
            onTap: () => context.push('/home/support'),
          ),

          const SizedBox(height: 8),

          _SectionTile(
            icon: Icons.logout_rounded,
            title: 'profile.sign_out'.tr(),
            isDestructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: 32),
          Text(
            'profile.version'.tr(namedArgs: {'version': '1.0.0'}),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.sign_out'.tr()),
        content: Text('profile.sign_out_confirm'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr())),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text('profile.sign_out'.tr()),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final isArabic = currentLocale.languageCode == 'ar';
    
    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text('profile.language'.tr(),
          style: Theme.of(context).textTheme.titleSmall),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurfaceRaised
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          isArabic ? 'profile.arabic'.tr() : 'profile.english'.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      onTap: () => _showLanguageDialog(context),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final currentLocale = context.locale;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('profile.language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              title: 'profile.arabic'.tr(),
              subtitle: 'العربية',
              isSelected: currentLocale.languageCode == 'ar',
              onTap: () {
                context.setLocale(const Locale('ar'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
            _LanguageOption(
              title: 'profile.english'.tr(),
              subtitle: 'English',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive
        ? (isDark ? AppColors.darkDanger : AppColors.danger)
        : null;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: color)),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
