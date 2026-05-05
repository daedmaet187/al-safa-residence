import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/household_member.dart';
import 'household_provider.dart';

const _relationships = [
  'Spouse',
  'Son',
  'Daughter',
  'Parent',
  'Sibling',
  'Other',
];

class MemberDetailScreen extends ConsumerStatefulWidget {
  const MemberDetailScreen({super.key, required this.memberId});
  final String memberId;

  @override
  ConsumerState<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends ConsumerState<MemberDetailScreen> {
  late TextEditingController _nameCtrl;
  String? _relationship;
  HouseholdAccess? _accessLevel;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRemoving = false;

  HouseholdMember? get _member {
    final state = ref.read(householdProvider).value;
    if (state == null) return null;
    try {
      return state.members.firstWhere((m) => m.id == widget.memberId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    final m = _member;
    _nameCtrl = TextEditingController(text: m?.name ?? '');
    _relationship = m?.relationship ?? _relationships.first;
    _accessLevel = m?.accessLevel ?? HouseholdAccess.limited;
    _nameCtrl.addListener(() => setState(() => _isDirty = true));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(householdProvider.notifier).updateMember(
            memberId: widget.memberId,
            name: _nameCtrl.text.trim(),
            relationship: _relationship,
            accessLevel: _accessLevel,
          );
      if (mounted) {
        setState(() => _isDirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _remove() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this household member? They will no longer be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRemoving = true);
    try {
      await ref
          .read(householdProvider.notifier)
          .removeMember(widget.memberId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final householdAsync = ref.watch(householdProvider);

    return householdAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Member Detail')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (state) {
        final member = state.members.where((m) => m.id == widget.memberId).firstOrNull;
        if (member == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Member Detail')),
            body: const Center(child: Text('Member not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(member.name),
            actions: [
              if (_isDirty)
                TextButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(color: AppColors.accent),
                        ),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      gradient: AppColors.goldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        member.initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Full Name',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        )),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                Text('Phone',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        )),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceRaised
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 18,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted),
                      const SizedBox(width: 12),
                      Text(member.phone,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Text('Cannot change',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSubtle
                                    : AppColors.textSubtle,
                              )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Text('Relationship',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        )),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _relationships.contains(_relationship)
                      ? _relationship
                      : _relationships.first,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.family_restroom_outlined),
                  ),
                  items: _relationships
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _relationship = v;
                        _isDirty = true;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Text('Access Level',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        )),
                const SizedBox(height: 8),
                SegmentedButton<HouseholdAccess>(
                  segments: const [
                    ButtonSegment(
                      value: HouseholdAccess.limited,
                      label: Text('Limited'),
                      icon: Icon(Icons.lock_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: HouseholdAccess.full,
                      label: Text('Full'),
                      icon: Icon(Icons.lock_open_outlined, size: 16),
                    ),
                  ],
                  selected: {_accessLevel ?? member.accessLevel},
                  onSelectionChanged: (s) => setState(() {
                    _accessLevel = s.first;
                    _isDirty = true;
                  }),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.accent;
                      }
                      return isDark ? AppColors.darkTextMuted : AppColors.textMuted;
                    }),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isRemoving ? null : _remove,
                    icon: _isRemoving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_remove_rounded),
                    label: const Text('Remove Member'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
