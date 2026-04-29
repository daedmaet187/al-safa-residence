import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/gate_provider.dart';

class GateScreen extends ConsumerWidget {
  const GateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myQrAsync = ref.watch(myQrProvider);
    final passesAsync = ref.watch(guestPassesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Access'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New Guest Pass',
            onPressed: () => context.push('/home/gate/create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // My QR Code
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [AppColors.darkSurface, AppColors.darkSurfaceRaised]
                      : [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'My Access QR',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  myQrAsync.when(
                    loading: () => const SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.white)),
                    ),
                    error: (_, __) => const Icon(Icons.error_outline,
                        color: Colors.white, size: 60),
                    data: (qr) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qr,
                        version: QrVersions.auto,
                        size: 190,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.primary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms),
                  const SizedBox(height: 12),
                  Text(
                    'Show this to security at the gate',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 28),

            // Guest passes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Guest Passes',
                    style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: () => context.push('/home/gate/create'),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('New Pass'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.darkAccent : AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            passesAsync.when(
              loading: () => const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (passes) {
                if (passes.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 48,
                            color: isDark
                                ? AppColors.darkTextSubtle
                                : AppColors.textSubtle),
                        const SizedBox(height: 12),
                        Text('No active guest passes',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text('Create a pass for visitors',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  );
                }
                return Column(
                  children: passes
                      .map((pass) => _GuestPassCard(pass: pass))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestPassCard extends ConsumerWidget {
  const _GuestPassCard({required this.pass});
  final GuestPass pass;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd MMM yyyy');

    return Dismissible(
      key: Key(pass.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 28),
      ),
      confirmDismiss: (dir) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Revoke Pass?'),
            content: Text('Remove access for ${pass.guestName}?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Revoke',
                      style: TextStyle(color: AppColors.danger))),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(gateNotifierProvider.notifier).revokePass(pass.id);
      },
      child: GestureDetector(
        onTap: () => context.push('/home/gate/${pass.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    pass.guestName.isNotEmpty
                        ? pass.guestName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pass.guestName,
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFmt.format(pass.validFrom)} — ${dateFmt.format(pass.validUntil)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusChip(
                  status: pass.isActive ? 'active' : pass.status),
            ],
          ),
        ),
      ),
    );
  }
}
