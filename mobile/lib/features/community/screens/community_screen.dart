import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/community_provider.dart';
import '../../../shared/models/announcement.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        }
      },
      child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community'),
          leading: Navigator.canPop(context)
              ? const BackButton()
              : null,
          automaticallyImplyLeading: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Announcements'),
              Tab(text: 'Community Rules'),
            ],
            labelColor: isDark ? AppColors.darkAccent : AppColors.accent,
            unselectedLabelColor:
                isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            indicatorColor:
                isDark ? AppColors.darkAccent : AppColors.accent,
          ),
        ),
        body: TabBarView(
          children: [
            // Announcements tab
            announcementsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (announcements) {
                if (announcements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 64,
                            color: isDark
                                ? AppColors.darkTextSubtle
                                : AppColors.textSubtle),
                        const SizedBox(height: 16),
                        Text('No announcements',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                // Sort: important first
                final sorted = [...announcements]
                  ..sort((a, b) {
                    if (a.isImportant && !b.isImportant) return -1;
                    if (!a.isImportant && b.isImportant) return 1;
                    return b.createdAt.compareTo(a.createdAt);
                  });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _AnnouncementCard(announcement: sorted[i]),
                );
              },
            ),

            // Community Rules tab
            const _CommunityRulesTab(),
          ],
        ),
      ),
    ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () =>
          context.push('/home/community/${announcement.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
                width: 5,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16)),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (announcement.isImportant) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'IMPORTANT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            dateFmt.format(announcement.createdAt),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      announcement.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      announcement.body,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityRulesTab extends StatelessWidget {
  const _CommunityRulesTab();

  static const _rules = [
    _Rule(
      icon: Icons.volume_off_rounded,
      title: 'Quiet Hours',
      body:
          'No loud noise between 10:00 PM and 8:00 AM. Please be considerate of your neighbors.',
    ),
    _Rule(
      icon: Icons.local_parking_rounded,
      title: 'Parking',
      body:
          'Only park in your designated space. Visitor parking is in the marked bays near the entrance.',
    ),
    _Rule(
      icon: Icons.delete_outline_rounded,
      title: 'Waste Disposal',
      body:
          'Use the designated waste chutes and recycling stations. Do not leave garbage in corridors.',
    ),
    _Rule(
      icon: Icons.pets_rounded,
      title: 'Pets',
      body:
          'Pets must be on a leash in common areas. Clean up after your pet immediately.',
    ),
    _Rule(
      icon: Icons.pool_rounded,
      title: 'Pool & Gym',
      body:
          'Amenities are open 6:00 AM – 11:00 PM. Proper attire required. Children under 12 must be supervised.',
    ),
    _Rule(
      icon: Icons.smoking_rooms_rounded,
      title: 'No Smoking',
      body:
          'Smoking is strictly prohibited inside all units, corridors, and covered areas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _rules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final rule = _rules[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkPrimaryLight
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(rule.icon,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule.title,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(rule.body,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Rule {
  final IconData icon;
  final String title;
  final String body;
  const _Rule({required this.icon, required this.title, required this.body});
}
