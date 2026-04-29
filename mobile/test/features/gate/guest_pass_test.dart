import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:al_safa_residence/features/gate/providers/gate_provider.dart';
import 'package:al_safa_residence/core/network/dio_client.dart';
import 'package:al_safa_residence/core/storage/secure_storage.dart';

// Minimal in-memory storage to avoid platform channel calls.
class _FakeStorage extends SecureStorageService {
  @override
  Future<String?> getAuthToken() async => 'test-token';
  @override
  Future<void> setAuthToken(String t) async {}
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> setRefreshToken(String t) async {}
  @override
  Future<String?> getUserRole() async => null;
  @override
  Future<void> setUserRole(String r) async {}
  @override
  Future<String?> getActiveUnitId() async => null;
  @override
  Future<void> setActiveUnitId(String id) async {}
  @override
  Future<void> clearAll() async {}
}

final _now = DateTime.now();
final _future = _now.add(const Duration(days: 7));
final _past = _now.subtract(const Duration(days: 1));

Map<String, dynamic> _passJson({
  String status = 'active',
  DateTime? validUntil,
  String qrCode = 'qr-uuid-1234',
}) =>
    {
      'id': 'pass-1',
      'guestName': 'Ali Hassan',
      'guestPhone': '+9647001234567',
      'guestIdNumber': null,
      'validFrom': _now.toIso8601String(),
      'validUntil': (validUntil ?? _future).toIso8601String(),
      'status': status,
      'qrCode': qrCode,
      'residentName': 'Resident User',
      'unitNumber': 'A-101',
    };

void main() {
  group('GuestPass model', () {
    test('fromJson creates correct instance with all fields', () {
      final pass = GuestPass.fromJson(_passJson());

      expect(pass.id, equals('pass-1'));
      expect(pass.guestName, equals('Ali Hassan'));
      expect(pass.guestPhone, equals('+9647001234567'));
      expect(pass.status, equals('active'));
      expect(pass.qrCode, equals('qr-uuid-1234'));
      expect(pass.residentName, equals('Resident User'));
      expect(pass.unitNumber, equals('A-101'));
    });

    test('isActive returns true for active pass with future validUntil', () {
      final pass = GuestPass.fromJson(_passJson(validUntil: _future));
      expect(pass.isActive, isTrue);
    });

    test('isActive returns false when validUntil is in the past', () {
      final pass = GuestPass.fromJson(_passJson(validUntil: _past));
      expect(pass.isActive, isFalse);
    });

    test('isActive returns false when status is not active', () {
      final pass = GuestPass.fromJson(_passJson(status: 'USED'));
      expect(pass.isActive, isFalse);
    });

    test('qrCode is non-empty after fromJson', () {
      final pass = GuestPass.fromJson(_passJson(qrCode: 'abc-def-ghi'));
      expect(pass.qrCode, isNotEmpty);
    });

    test('qrCode falls back to id when missing from JSON', () {
      final json = _passJson()..remove('qrCode');
      final pass = GuestPass.fromJson(json);
      expect(pass.qrCode, equals('pass-1'));
    });
  });

  group('GateNotifier.createPass', () {
    test('createPass with valid data succeeds and returns GuestPass', () async {
      final passJson = _passJson();
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(
          Response(requestOptions: opts, data: passJson, statusCode: 201),
        ),
      ));

      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(_FakeStorage()),
        dioProvider.overrideWithValue(dio),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(gateNotifierProvider.notifier);
      final pass = await notifier.createPass(
        guestName: 'Ali Hassan',
        guestPhone: '+9647001234567',
        validFrom: _now,
        validUntil: _future,
      );

      expect(pass.id, equals('pass-1'));
      expect(pass.guestName, equals('Ali Hassan'));
      expect(pass.qrCode, isNotEmpty);
    });

    test('createPass result has non-empty qrCode', () async {
      final passJson = _passJson(qrCode: 'generated-uuid-xyz');
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (opts, handler) => handler.resolve(
          Response(requestOptions: opts, data: passJson, statusCode: 201),
        ),
      ));

      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(_FakeStorage()),
        dioProvider.overrideWithValue(dio),
      ]);
      addTearDown(container.dispose);

      final pass = await container.read(gateNotifierProvider.notifier).createPass(
        guestName: 'Sara',
        guestPhone: '+9647009999',
        validFrom: _now,
        validUntil: _future,
      );

      expect(pass.qrCode, isNotEmpty);
      expect(pass.qrCode, equals('generated-uuid-xyz'));
    });
  });
}
