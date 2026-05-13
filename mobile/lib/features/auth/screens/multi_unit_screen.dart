import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/unit.dart';
import '../../../shared/widgets/gold_button.dart';
import '../providers/auth_provider.dart';

class MultiUnitScreen extends ConsumerStatefulWidget {
  const MultiUnitScreen({super.key});

  @override
  ConsumerState<MultiUnitScreen> createState() => _MultiUnitScreenState();
}

class _MultiUnitScreenState extends ConsumerState<MultiUnitScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final units = authState?.units ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('multi_unit.select_unit'.tr(),
                      style: Theme.of(context).textTheme.headlineMedium)
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.2),
              const SizedBox(height: 8),
              Text(
                'multi_unit.multiple_units_hint'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted),
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: units.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final unit = units[i];
                    final isSelected = _selectedId == unit.id;
                    return _UnitOption(
                      unit: unit,
                      isSelected: isSelected,
                      onTap: () => setState(() => _selectedId = unit.id),
                    ).animate(delay: Duration(milliseconds: 100 + i * 80))
                        .fadeIn()
                        .slideY(begin: 0.2);
                  },
                ),
              ),
              const SizedBox(height: 24),
              GoldButton(
                label: 'multi_unit.continue'.tr(),
                icon: Icons.arrow_forward_rounded,
                onPressed: _selectedId != null
                    ? () async {
                        await ref
                            .read(authProvider.notifier)
                            .switchUnit(_selectedId!);
                        if (context.mounted) context.go('/home');
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnitOption extends StatelessWidget {
  const _UnitOption({
    required this.unit,
    required this.isSelected,
    required this.onTap,
  });
  final ResidenceUnit unit;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : (isDark ? AppColors.darkSurfaceRaised : AppColors.background),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    unit.number,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.darkPrimary : AppColors.primary),
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'F${unit.floor}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white.withOpacity(0.7)
                          : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('home.unit'.tr(namedArgs: {'number': unit.number}),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isSelected
                              ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary)
                              : null)),
                  const SizedBox(height: 2),
                  Text(
                    'multi_unit.unit_info'.tr(namedArgs: {
                      'type': unit.type,
                      'bedrooms': unit.bedrooms.toString(),
                      'floor': unit.floor.toString(),
                    }),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    unit.buildingName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.primary),
          ],
        ),
      ),
    );
  }
}
