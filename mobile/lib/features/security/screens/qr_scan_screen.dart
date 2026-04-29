import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/security_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  bool _hasResult = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(String rawValue) async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);
    await _controller.stop();

    await ref.read(scanNotifierProvider.notifier).scan(rawValue);

    if (mounted) setState(() => _hasResult = true);
  }

  void _reset() {
    ref.read(scanNotifierProvider.notifier).reset();
    setState(() {
      _isScanning = true;
      _hasResult = false;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(scanNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan QR Code',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera view
          if (_isScanning)
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcode = capture.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _handleScan(barcode!.rawValue!);
                }
              },
            ),

          // Scan overlay
          if (_isScanning) _ScanOverlay(),

          // Result overlay
          if (_hasResult && result != null)
            _ScanResultOverlay(result: result, onReset: _reset),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Darkened overlay with cutout
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                color: Colors.transparent,
              ),
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Corner markers
        Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: Stack(
              children: [
                _Corner(Alignment.topLeft),
                _Corner(Alignment.topRight),
                _Corner(Alignment.bottomLeft),
                _Corner(Alignment.bottomRight),
              ],
            ),
          ),
        ),
        // Instructions
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Text(
            'Align QR code within the frame',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner(this.alignment);
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment == Alignment.topLeft ||
        alignment == Alignment.topRight;
    final isLeft = alignment == Alignment.topLeft ||
        alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: 28,
        height: 28,
        child: CustomPaint(
          painter: _CornerPainter(isTop: isTop, isLeft: isLeft),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.isTop, required this.isLeft});
  final bool isTop;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final x = isLeft ? 0.0 : size.width;
    final y = isTop ? 0.0 : size.height;
    final dx = isLeft ? size.width * 0.6 : -size.width * 0.6;
    final dy = isTop ? size.height * 0.6 : -size.height * 0.6;

    final path = Path()
      ..moveTo(x + dx, y)
      ..lineTo(x, y)
      ..lineTo(x, y + dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScanResultOverlay extends StatelessWidget {
  const _ScanResultOverlay({required this.result, required this.onReset});
  final GateScanResult result;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String statusText;

    switch (result.status) {
      case ScanResultStatus.approved:
        bgColor = AppColors.gateApproved;
        textColor = Colors.white;
        icon = Icons.check_circle_rounded;
        statusText = 'APPROVED';
        break;
      case ScanResultStatus.denied:
        bgColor = AppColors.gateDenied;
        textColor = Colors.white;
        icon = Icons.cancel_rounded;
        statusText = 'DENIED';
        break;
      case ScanResultStatus.expired:
        bgColor = AppColors.gateWaiting;
        textColor = Colors.white;
        icon = Icons.timer_off_rounded;
        statusText = 'EXPIRED';
        break;
      default:
        bgColor = AppColors.textMuted;
        textColor = Colors.white;
        icon = Icons.help_outline_rounded;
        statusText = 'UNKNOWN';
    }

    return Container(
      color: bgColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 96)
                  .animate()
                  .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 400.ms,
                      curve: Curves.easeOutBack)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 24),
              Text(
                statusText,
                style: TextStyle(
                  color: textColor,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 32),
              if (result.guestName != null) ...[
                _InfoRow(
                    label: 'Guest',
                    value: result.guestName!,
                    textColor: textColor),
                const SizedBox(height: 8),
              ],
              if (result.residentName != null) ...[
                _InfoRow(
                    label: 'Resident',
                    value: result.residentName!,
                    textColor: textColor),
                const SizedBox(height: 8),
              ],
              if (result.unitNumber != null) ...[
                _InfoRow(
                    label: 'Unit',
                    value: result.unitNumber!,
                    textColor: textColor),
                const SizedBox(height: 8),
              ],
              if (result.validUntil != null) ...[
                _InfoRow(
                    label: 'Valid Until',
                    value: result.validUntil!,
                    textColor: textColor),
              ],
              if (result.message != null) ...[
                const SizedBox(height: 16),
                Text(
                  result.message!,
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              GestureDetector(
                onTap: onReset,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Scan Again',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, required this.textColor});
  final String label;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label: ',
            style: TextStyle(
              color: textColor.withOpacity(0.75),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            )),
        Text(value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
