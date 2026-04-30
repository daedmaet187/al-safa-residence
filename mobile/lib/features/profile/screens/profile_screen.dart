import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(title: const Text('Profile')),
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
                  user?.name ?? 'Resident',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                if (user?.phone.isNotEmpty == true)
                  Text(
                    user!.phone,
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
                    'To update your information, contact admin',
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
            title: 'ID Documents',
            onTap: () {},
          ),
          Consumer(builder: (ctx, ref, _) {
            final themeMode = ref.watch(themeModeProvider);
            final isDarkNow = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    MediaQuery.platformBrightnessOf(ctx) == Brightness.dark);
            return ListTile(
              leading: Icon(isDarkNow ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              title: Text(isDarkNow ? 'Switch to Light Mode' : 'Switch to Dark Mode',
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
            icon: Icons.help_outline_rounded,
            title: 'Help & Support',
            onTap: () {},
          ),

          const SizedBox(height: 8),

          _SectionTile(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            isDestructive: true,
            onTap: () => _confirmLogout(context, ref),
          ),

          const SizedBox(height: 32),
          Text(
            'Al-Safa Residence v1.0.0',
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
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
