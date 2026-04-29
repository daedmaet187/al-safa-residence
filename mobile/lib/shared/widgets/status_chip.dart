import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.inverted = false});
  final String status;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = _config(status.toLowerCase(), isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: inverted ? Colors.white.withOpacity(0.2) : cfg.bg,
        borderRadius: BorderRadius.circular(100),
        border: inverted
            ? Border.all(color: Colors.white.withOpacity(0.4))
            : null,
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: inverted ? Colors.white : cfg.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _ChipConfig _config(String s, bool isDark) {
    switch (s) {
      case 'paid':
        return _ChipConfig(
          label: 'Paid',
          bg: isDark ? AppColors.darkSuccessLight : AppColors.successLight,
          fg: isDark ? AppColors.darkSuccess : AppColors.success,
        );
      case 'overdue':
        return _ChipConfig(
          label: 'Overdue',
          bg: isDark ? AppColors.darkDangerLight : AppColors.dangerLight,
          fg: isDark ? AppColors.darkDanger : AppColors.danger,
        );
      case 'pending':
        return _ChipConfig(
          label: 'Pending',
          bg: isDark ? AppColors.darkWarningLight : AppColors.warningLight,
          fg: isDark ? AppColors.darkWarning : AppColors.warning,
        );
      case 'in_progress':
      case 'inprogress':
        return _ChipConfig(
          label: 'In Progress',
          bg: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
          fg: isDark ? AppColors.darkPrimary : AppColors.primary,
        );
      case 'resolved':
      case 'completed':
        return _ChipConfig(
          label: s == 'resolved' ? 'Resolved' : 'Completed',
          bg: isDark ? AppColors.darkSuccessLight : AppColors.successLight,
          fg: isDark ? AppColors.darkSuccess : AppColors.success,
        );
      case 'approved':
        return _ChipConfig(
          label: 'Approved',
          bg: isDark ? AppColors.darkSuccessLight : AppColors.successLight,
          fg: isDark ? AppColors.darkGateApproved : AppColors.gateApproved,
        );
      case 'denied':
        return _ChipConfig(
          label: 'Denied',
          bg: isDark ? AppColors.darkDangerLight : AppColors.dangerLight,
          fg: isDark ? AppColors.darkGateDenied : AppColors.gateDenied,
        );
      case 'expired':
        return _ChipConfig(
          label: 'Expired',
          bg: isDark ? AppColors.darkWarningLight : AppColors.warningLight,
          fg: isDark ? AppColors.darkWarning : AppColors.warning,
        );
      case 'active':
        return _ChipConfig(
          label: 'Active',
          bg: isDark ? AppColors.darkSuccessLight : AppColors.successLight,
          fg: isDark ? AppColors.darkSuccess : AppColors.success,
        );
      default:
        return _ChipConfig(
          label: s[0].toUpperCase() + s.substring(1),
          bg: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
          fg: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
        );
    }
  }
}

class _ChipConfig {
  final String label;
  final Color bg;
  final Color fg;
  const _ChipConfig({required this.label, required this.bg, required this.fg});
}
