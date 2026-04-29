import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

enum ScanResultStatus { approved, denied, expired, unknown }

class GateScanResult {
  final ScanResultStatus status;
  final String? guestName;
  final String? residentName;
  final String? unitNumber;
  final String? validUntil;
  final String? message;
  final DateTime scannedAt;

  const GateScanResult({
    required this.status,
    this.guestName,
    this.residentName,
    this.unitNumber,
    this.validUntil,
    this.message,
    required this.scannedAt,
  });

  factory GateScanResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'unknown';
    final status = {
      'approved': ScanResultStatus.approved,
      'denied': ScanResultStatus.denied,
      'expired': ScanResultStatus.expired,
    }[statusStr] ??
        ScanResultStatus.unknown;

    return GateScanResult(
      status: status,
      guestName: json['guestName'] as String?,
      residentName: json['residentName'] as String?,
      unitNumber: json['unitNumber'] as String?,
      validUntil: json['validUntil'] as String?,
      message: json['message'] as String?,
      scannedAt: DateTime.now(),
    );
  }
}

class VisitorLogEntry {
  final String id;
  final String guestName;
  final String unitNumber;
  final ScanResultStatus status;
  final DateTime scannedAt;

  const VisitorLogEntry({
    required this.id,
    required this.guestName,
    required this.unitNumber,
    required this.status,
    required this.scannedAt,
  });

  factory VisitorLogEntry.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'unknown';
    final status = {
      'approved': ScanResultStatus.approved,
      'denied': ScanResultStatus.denied,
      'expired': ScanResultStatus.expired,
    }[statusStr] ??
        ScanResultStatus.unknown;

    return VisitorLogEntry(
      id: json['id'] as String,
      guestName: json['guestName'] as String? ?? 'Unknown',
      unitNumber: json['unitNumber'] as String? ?? '',
      status: status,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}

final visitorLogProvider =
    FutureProvider<List<VisitorLogEntry>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/gate/log');
  final list = response.data as List<dynamic>;
  return list
      .map((e) => VisitorLogEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});

class ScanNotifier extends StateNotifier<GateScanResult?> {
  ScanNotifier(this._ref) : super(null);
  final Ref _ref;

  Future<void> scan(String qrCode) async {
    final dio = _ref.read(dioProvider);
    try {
      final response = await dio.post('/gate/scan', data: {'qrCode': qrCode});
      state = GateScanResult.fromJson(response.data as Map<String, dynamic>);
      _ref.invalidate(visitorLogProvider);
    } catch (_) {
      state = GateScanResult(
        status: ScanResultStatus.denied,
        message: 'Invalid QR code',
        scannedAt: DateTime.now(),
      );
    }
  }

  void reset() => state = null;
}

final scanNotifierProvider =
    StateNotifierProvider<ScanNotifier, GateScanResult?>(
  (ref) => ScanNotifier(ref),
);

// Security login
class SecurityAuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(secureStorageProvider);
    final role = await storage.getUserRole();
    return role == 'security';
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final storage = ref.read(secureStorageProvider);
      final resp = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'role': 'security',
      });
      final token = resp.data['accessToken'] as String;
      await storage.setAuthToken(token);
      await storage.setUserRole('security');
      return true;
    });
  }
}

final securityAuthProvider =
    AsyncNotifierProvider<SecurityAuthNotifier, bool>(
        SecurityAuthNotifier.new);
