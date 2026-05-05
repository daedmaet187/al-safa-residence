import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/household_member.dart';
import '../../auth/providers/auth_provider.dart';
import 'household_provider.dart';
import 'add_member_sheet.dart';

class HouseholdMembersScreen extends ConsumerWidget {
  const HouseholdMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(householdProvider);
    final authState = ref.watch(authProvider).value;
    final unit = authState?.activeUnit;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Members'),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddSheet(context, ref),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
            ),
          ),
        ],
      ),
      body: householdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
              const SizedBox(height: 12),
              Text('Failed to load members: $e',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(householdProvider.notifier).fetchMembers(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) => _buildBody(context, ref, state, unit?.number, isDark),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref,
      HouseholdState state, String? unitNumber, bool isDark) {
    final members = state.members;

    return Column(
      children: [
        if (unitNumber != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.home_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  '${members.length} member${members.length != 1 ? 's' : ''} registered for Unit $unitNumber',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...members.map((m) => _MemberCard(
                    member: m,
                    isDark: isDark,
                    onTap: () => context.push('/home/household-members/${m.id}'),
                  )),
              const SizedBox(height: 8),
              _AddMemberCard(
                isDark: isDark,
                onTap: () => _showAddSheet(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddMemberSheet(),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isDark,
    required this.onTap,
  });
  final HouseholdMember member;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFullAccess = member.accessLevel == HouseholdAccess.full;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            gradient: AppColors.goldGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              member.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(member.name,
            style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          member.relationship,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isFullAccess
                    ? AppColors.accent.withOpacity(0.15)
                    : (isDark
                        ? AppColors.darkSurfaceRaised
                        : AppColors.background),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isFullAccess
                      ? AppColors.accent.withOpacity(0.4)
                      : (isDark ? AppColors.darkBorder : AppColors.border),
                ),
              ),
              child: Text(
                isFullAccess ? 'Full' : 'Limited',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isFullAccess
                      ? AppColors.accent
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AddMemberCard extends StatelessWidget {
  const _AddMemberCard({required this.isDark, required this.onTap});
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              '+ Add Member',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
