import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/gate_provider.dart';

class QrDisplayScreen extends ConsumerWidget {
  const QrDisplayScreen({super.key, required this.passId});
  final String passId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesAsync = ref.watch(guestPassesProvider);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Guest Pass')),
      body: passesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (passes) {
          GuestPass? pass;
          try {
            pass = passes.firstWhere((p) => p.id == passId);
          } catch (_) {
            return const Center(child: Text('Pass not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR Code card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: pass.qrCode,
                          version: QrVersions.auto,
                          size: 220,
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
                      const SizedBox(height: 20),
                      Text(
                        pass.guestName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(pass.guestPhone,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      StatusChip(
                          status: pass.isActive ? 'active' : pass.status),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Details card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Valid From',
                          value: dateFmt.format(pass.validFrom)),
                      const Divider(height: 20),
                      _DetailRow(
                          icon: Icons.event_outlined,
                          label: 'Valid Until',
                          value: dateFmt.format(pass.validUntil)),
                      if (pass.guestIdNumber != null) ...[
                        const Divider(height: 20),
                        _DetailRow(
                            icon: Icons.badge_outlined,
                            label: 'ID Number',
                            value: pass.guestIdNumber!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Share button
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Share QR code functionality')),
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Pass'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
