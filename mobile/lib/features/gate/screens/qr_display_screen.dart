import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/gate_provider.dart';

class QrDisplayScreen extends ConsumerStatefulWidget {
  const QrDisplayScreen({super.key, required this.passId});
  final String passId;

  @override
  ConsumerState<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends ConsumerState<QrDisplayScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _sharing = false;

  Future<void> _shareQr(GuestPass pass) async {
    setState(() => _sharing = true);
    try {
      // Capture QR widget as image
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _shareText(pass);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _shareText(pass);
        return;
      }

      final tmpDir = await getTemporaryDirectory();
      final file = File('${tmpDir.path}/guest_pass_${pass.id}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Guest Pass — Al-Safa Residence',
        text:
            'Guest: ${pass.guestName}\nValid: ${DateFormat('dd MMM yyyy').format(pass.validFrom)} — ${DateFormat('dd MMM yyyy').format(pass.validUntil)}\n\nShow this QR code at the gate.',
      );
    } catch (_) {
      _shareText(pass);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _shareText(GuestPass pass) {
    Share.share(
      'Guest Pass for ${pass.guestName}\nValid: ${DateFormat('dd MMM yyyy').format(pass.validFrom)} — ${DateFormat('dd MMM yyyy').format(pass.validUntil)}\nQR Code: ${pass.qrCode}\n\nAl-Safa Residence',
      subject: 'Guest Pass — Al-Safa Residence',
    );
  }

  @override
  Widget build(BuildContext context) {
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
            pass = passes.firstWhere((p) => p.id == widget.passId);
          } catch (_) {
            return const Center(child: Text('Pass not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // QR Code card — wrapped in RepaintBoundary for capture
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outline),
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
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(12),
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

                // Share button — real share
                FilledButton.icon(
                  onPressed: _sharing ? null : () => _shareQr(pass!),
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.share_rounded),
                  label: Text(_sharing ? 'Preparing...' : 'Share Pass'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.primary,
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
        Icon(icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
