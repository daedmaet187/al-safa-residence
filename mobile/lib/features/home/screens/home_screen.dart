import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/models/announcement.dart';
import '../providers/home_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../community/providers/community_provider.dart';
import '../../../shared/models/announcement.dart' as ann_model;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final summaryAsync = ref.watch(homeSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = authState?.user;
    final unit = authState?.activeUnit;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkSurface, AppColors.darkSurfaceRaised]
                      : [AppColors.primary, AppColors.secondary],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good ${_greeting()},',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.name.split(' ').first ?? 'Resident',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Unit pill
                          if (unit != null)
                            GestureDetector(
                              onTap: () => context.push('/home/unit-switcher'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.home_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Unit ${unit.number}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded,
                                        color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          // Notifications
                          GestureDetector(
                            onTap: () => _showNotifications(context, ref),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Overdue alert
                      summaryAsync.when(
                        data: (summary) => summary.overdueBills > 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.dangerLight.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${summary.overdueBills} overdue bill${summary.overdueBills > 1 ? 's' : ''}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () =>
                                            context.go('/home/payments'),
                                        child: const Text('Pay now',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Quick actions grid
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Services',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.9,
                    children: [
                      _QuickAction(
                        icon: Icons.home_rounded,
                        label: 'My Unit',
                        route: '/home/unit',
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.build_rounded,
                        label: 'Maintenance',
                        route: '/home/maintenance',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                        ),
                        badgeAsync: summaryAsync.when(
                          data: (s) => s.openMaintenanceRequests,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'Pay Bills',
                        route: '/home/payments',
                        gradient: AppColors.goldGradient,
                        badgeAsync: summaryAsync.when(
                          data: (s) => s.overdueBills,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                        badgeDanger: true,
                      ),
                      _QuickAction(
                        icon: Icons.qr_code_2_rounded,
                        label: 'Guest Pass',
                        route: '/home/gate',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0369A1), Color(0xFF075985)],
                        ),
                        badgeAsync: summaryAsync.when(
                          data: (s) => s.activeGuestPasses,
                          loading: () => 0,
                          error: (_, __) => 0,
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.campaign_rounded,
                        label: 'Updates',
                        route: '/home/community',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF047857)],
                        ),
                      ),
                      _QuickAction(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        route: '/home/profile',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDB2777), Color(0xFFBE185D)],
                        ),
                      ),
                    ].animate(interval: 60.ms).fadeIn().scale(
                        begin: const Offset(0.85, 0.85),
                        curve: Curves.easeOutBack),
                  ),
                ],
              ),
            ),
          ),

          // Announcements preview
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
            sliver: SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (summary) {
                  if (summary.recentAnnouncements.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Announcements',
                        action: 'See all',
                        onAction: () => context.go('/home/community'),
                      ),
                      const SizedBox(height: 12),
                      ...summary.recentAnnouncements.map((a) =>
                          _AnnouncementPreview(announcement: a)),
                    ],
                  );
                },
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  void _showNotifications(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotificationsSheet(ref: ref),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.route,
    required this.gradient,
    this.badgeAsync = 0,
    this.badgeDanger = false,
  });
  final IconData icon;
  final String label;
  final String route;
  final Gradient gradient;
  final int badgeAsync;
  final bool badgeDanger;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                if (badgeAsync > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: badgeDanger
                            ? AppColors.danger
                            : AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isDark
                                ? AppColors.darkSurface
                                : AppColors.surface,
                            width: 2),
                      ),
                      child: Center(
                        child: Text(
                          badgeAsync > 9 ? '9+' : '$badgeAsync',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementPreview extends StatelessWidget {
  const _AnnouncementPreview({required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: announcement.isImportant
              ? AppColors.accent.withOpacity(0.5)
              : (isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      child: Row(
        children: [
          if (announcement.isImportant)
            Container(
              width: 4,
              height: 60,
              decoration: const BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(14)),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (announcement.isImportant)
                          Text('IMPORTANT',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: isDark
                                    ? AppColors.darkAccent
                                    : AppColors.accent,
                              )),
                        Text(
                          announcement.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          announcement.body,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dateFmt.format(announcement.createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications bottom sheet ────────────────────────────────────────────────

class _NotificationsSheet extends ConsumerWidget {
  const _NotificationsSheet({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef watchRef) {
    final announcementsAsync = watchRef.watch(announcementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined),
                  const SizedBox(width: 10),
                  Text('Notifications',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: announcementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('Could not load notifications')),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined,
                              size: 56,
                              color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
                          const SizedBox(height: 12),
                          Text('No notifications',
                              style: Theme.of(context).textTheme.titleSmall),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: item.isImportant
                                ? AppColors.accent.withOpacity(0.4)
                                : (isDark ? AppColors.darkBorder : AppColors.border),
                          ),
                        ),
                        tileColor: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: item.isImportant
                                ? AppColors.accent.withOpacity(0.15)
                                : (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.isImportant
                                ? Icons.campaign_rounded
                                : Icons.notifications_rounded,
                            size: 20,
                            color: item.isImportant
                                ? AppColors.accent
                                : (isDark ? AppColors.darkPrimary : AppColors.primary),
                          ),
                        ),
                        title: Text(item.title,
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        subtitle: Text(item.body,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/home/community/${item.id}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
