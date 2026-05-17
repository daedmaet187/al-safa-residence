import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class GuestPass {
  final String id;
  final String guestName;
  final String guestPhone;
  final String? guestIdNumber;
  final DateTime validFrom;
  final DateTime validUntil;
  final String status;
  final String qrCode;
  final String residentName;
  final String unitNumber;

  const GuestPass({
    required this.id,
    required this.guestName,
    required this.guestPhone,
    this.guestIdNumber,
    required this.validFrom,
    required this.validUntil,
    required this.status,
    required this.qrCode,
    required this.residentName,
    required this.unitNumber,
  });

  factory GuestPass.fromJson(Map<String, dynamic> json) => GuestPass(
        id: json['id'] as String,
        guestName: json['guestName'] as String,
        guestPhone: json['guestPhone'] as String,
        guestIdNumber: json['guestIdNumber'] as String?,
        validFrom: DateTime.parse(json['validFrom'] as String),
        validUntil: DateTime.parse(json['validUntil'] as String),
        status: json['status'] as String? ?? 'active',
        qrCode: json['qrCode'] as String? ?? json['id'] as String,
        residentName: json['residentName'] as String? ?? '',
        unitNumber: json['unitNumber'] as String? ?? '',
      );

  bool get isActive =>
      status == 'active' && DateTime.now().isBefore(validUntil);

  String get displayStatus {
    if (status == 'active' && DateTime.now().isAfter(validUntil)) return 'expired';
    return status;
  }
}

// My resident QR
final myQrProvider = FutureProvider<String>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/gate/my-qr');
  return response.data['qrCode'] as String;
});

// Guest passes list
final guestPassesProvider = FutureProvider<List<GuestPass>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/gate/passes');
  final list = response.data as List<dynamic>;
  return list.map((e) => GuestPass.fromJson(e as Map<String, dynamic>)).toList();
});

// Create / revoke
class GateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<GuestPass> createPass({
    required String guestName,
    required String guestPhone,
    String? guestIdNumber,
    required DateTime validFrom,
    required DateTime validUntil,
  }) async {
    final dio = ref.read(dioProvider);
    final response = await dio.post('/gate/passes', data: {
      'guestName': guestName,
      'guestPhone': guestPhone,
      if (guestIdNumber != null) 'guestIdNumber': guestIdNumber,
      'validFrom': validFrom.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
    });
    ref.invalidate(guestPassesProvider);
    return GuestPass.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> revokePass(String passId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/gate/passes/$passId');
    ref.invalidate(guestPassesProvider);
  }
}

final gateNotifierProvider =
    AsyncNotifierProvider<GateNotifier, void>(GateNotifier.new);
