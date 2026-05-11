import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/household_member.dart';
import '../../../shared/widgets/gold_button.dart';
import 'household_provider.dart';

const _relationships = [
  'Spouse',
  'Son',
  'Daughter',
  'Parent',
  'Sibling',
  'Other',
];

class AddMemberSheet extends ConsumerStatefulWidget {
  const AddMemberSheet({super.key});

  @override
  ConsumerState<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends ConsumerState<AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relationship = _relationships.first;
  HouseholdAccess _accessLevel = HouseholdAccess.limited;
  bool _isLoading = false;
  String? _error;

  static final _phoneRegex = RegExp(r'^\+?\d{10,15}$');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(householdProvider.notifier).addMember(
            name: name,
            phone: phone,
            relationship: _relationship,
            accessLevel: _accessLevel,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Add Household Member',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Enter a valid name';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+964 750 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone is required';
                    if (!_phoneRegex.hasMatch(v.trim())) {
                      return 'Enter a valid phone number (10–15 digits)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<String>(
            value: _relationship,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              prefixIcon: Icon(Icons.family_restroom_outlined),
            ),
            items: _relationships
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _relationship = v);
            },
          ),
          const SizedBox(height: 14),

          Text('Access Level',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
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
            selected: {_accessLevel},
            onSelectionChanged: (s) =>
                setState(() => _accessLevel = s.first),
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.accent;
                }
                return isDark ? AppColors.darkTextMuted : AppColors.textMuted;
              }),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.danger.withOpacity(0.3)),
              ),
              child: Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 20),
          GoldButton(
            label: 'Add Member',
            icon: Icons.person_add_rounded,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
