import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';

String? _extractUnitNumber(Map<String, dynamic> json) {
  try {
    final resident = json['resident'] as Map<String, dynamic>?;
    if (resident == null) return null;
    final assignments = resident['unitAssignments'] as List<dynamic>?;
    if (assignments == null || assignments.isEmpty) return null;
    final unit = (assignments[0] as Map<String, dynamic>)['unit'] as Map<String, dynamic>?;
    return unit?['number'] as String?;
  } catch (_) {
    return null;
  }
}

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
    // Backend returns 'result' field (APPROVED/DENIED/EXPIRED), not 'status'
    final raw = (json['result'] as String? ?? json['status'] as String? ?? 'unknown').toLowerCase();
    final status = {
      'approved': ScanResultStatus.approved,
      'denied': ScanResultStatus.denied,
      'expired': ScanResultStatus.expired,
    }[raw] ??
        ScanResultStatus.unknown;

    return GateScanResult(
      status: status,
      guestName: json['guestName'] as String?,
      residentName: (json['residentName'] as String?) ??
          ((json['resident'] as Map?)?['name']) as String?,
      unitNumber: (json['unitNumber'] as String?) ?? _extractUnitNumber(json),
      validUntil: json['validUntil'] as String?,
      message: (json['reason'] as String?) ?? (json['message'] as String?),
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
    final resultStr = (json['result'] as String? ?? json['status'] as String? ?? 'unknown').toLowerCase();
    final status = {
      'approved': ScanResultStatus.approved,
      'denied': ScanResultStatus.denied,
      'expired': ScanResultStatus.expired,
    }[resultStr] ??
        ScanResultStatus.unknown;

    // Backend nests guest info under guestPass
    final guestPass = json['guestPass'] as Map<String, dynamic>?;
    final guestName = (json['guestName'] as String?) ??
        guestPass?['guestName'] as String? ?? 'Unknown';
    final unitNumber = (json['unitNumber'] as String?) ?? '';

    return VisitorLogEntry(
      id: json['id'] as String,
      guestName: guestName,
      unitNumber: unitNumber,
      status: status,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );
  }
}

final visitorLogProvider =
    FutureProvider<List<VisitorLogEntry>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/guests/log');
  final raw = response.data;
  final List<dynamic> list;
  if (raw is Map<String, dynamic> && raw.containsKey('data')) {
    list = raw['data'] as List<dynamic>;
  } else if (raw is List<dynamic>) {
    list = raw;
  } else {
    list = [];
  }
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
      final response = await dio.post('/guests/scan', data: {'qrCode': qrCode});
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

// Security login — phone OTP flow (same as resident)
class SecurityAuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage = ref.read(secureStorageProvider);
    final role = await storage.getUserRole();
    return role == 'SECURITY' || role == 'security';
  }

  Future<void> sendOtp({required String phone}) async {
    final dio = ref.read(dioProvider);
    await dio.post('/auth/send-otp', data: {'phone': phone, 'role': 'SECURITY'});
  }

  Future<void> verifyOtp({required String phone, required String otp}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final storage = ref.read(secureStorageProvider);
      final resp = await dio.post('/auth/verify-otp', data: {'phone': phone, 'otp': otp, 'role': 'SECURITY'});
      final role = resp.data['role'] as String? ?? 'SECURITY';
      if (role.toUpperCase() != 'SECURITY') {
        throw Exception('This number is not a security guard account');
      }
      final token = resp.data['accessToken'] as String;
      await storage.setAuthToken(token);
      await storage.setUserRole(role);
      return true;
    });
  }
}

final securityAuthProvider =
    AsyncNotifierProvider<SecurityAuthNotifier, bool>(
        SecurityAuthNotifier.new);
