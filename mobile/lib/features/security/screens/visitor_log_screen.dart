import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/security_provider.dart';

class VisitorLogScreen extends ConsumerWidget {
  const VisitorLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(visitorLogProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.sidebar,
        foregroundColor: Colors.white,
        title: const Text('Visitor Log',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: logAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (log) {
          if (log.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextSubtle
                          : AppColors.textSubtle),
                  const SizedBox(height: 16),
                  Text('No scans yet',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: log.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _LogEntry(entry: log[i]),
          );
        },
      ),
    );
  }
}

class _LogEntry extends StatelessWidget {
  const _LogEntry({required this.entry});
  final VisitorLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeFmt = DateFormat('HH:mm');
    final dateFmt = DateFormat('dd MMM');

    Color iconColor;
    IconData icon;
    Color bgColor;

    switch (entry.status) {
      case ScanResultStatus.approved:
        iconColor = isDark ? AppColors.darkGateApproved : AppColors.gateApproved;
        icon = Icons.check_circle_rounded;
        bgColor = isDark ? AppColors.darkSuccessLight : AppColors.successLight;
        break;
      case ScanResultStatus.denied:
        iconColor = isDark ? AppColors.darkGateDenied : AppColors.gateDenied;
        icon = Icons.cancel_rounded;
        bgColor = isDark ? AppColors.darkDangerLight : AppColors.dangerLight;
        break;
      case ScanResultStatus.expired:
        iconColor = isDark ? AppColors.darkGateWaiting : AppColors.gateWaiting;
        icon = Icons.timer_off_rounded;
        bgColor = isDark ? AppColors.darkWarningLight : AppColors.warningLight;
        break;
      default:
        iconColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
        icon = Icons.help_outline_rounded;
        bgColor = isDark ? AppColors.darkSurfaceRaised : AppColors.background;
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(entry.guestName,
          style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(
        'Unit ${entry.unitNumber}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(timeFmt.format(entry.scannedAt),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          Text(dateFmt.format(entry.scannedAt),
              style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
