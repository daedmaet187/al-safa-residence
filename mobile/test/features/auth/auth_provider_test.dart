import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:al_safa_residence/features/auth/providers/auth_provider.dart';
import 'package:al_safa_residence/core/storage/secure_storage.dart';
import 'package:al_safa_residence/core/network/dio_client.dart';

// In-memory fake — overrides all methods so FlutterSecureStorage is never called.
class _FakeStorage extends SecureStorageService {
  final Map<String, String?> _d = {};

  @override
  Future<String?> getAuthToken() async => _d['auth_token'];
  @override
  Future<void> setAuthToken(String t) async => _d['auth_token'] = t;

  @override
  Future<String?> getRefreshToken() async => _d['refresh_token'];
  @override
  Future<void> setRefreshToken(String t) async => _d['refresh_token'] = t;

  @override
  Future<String?> getUserRole() async => _d['user_role'];
  @override
  Future<void> setUserRole(String r) async => _d['user_role'] = r;

  @override
  Future<String?> getActiveUnitId() async => _d['active_unit_id'];
  @override
  Future<void> setActiveUnitId(String id) async => _d['active_unit_id'] = id;

  @override
  Future<void> clearAll() async => _d.clear();
}

Dio _fakeDio(Map<String, dynamic> responses, {bool failAll = false}) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (opts, handler) {
      if (failAll) {
        handler.reject(DioException(
          requestOptions: opts,
          type: DioExceptionType.unknown,
        ));
        return;
      }
      final entry = responses.entries.firstWhere(
        (e) => opts.path.endsWith(e.key),
        orElse: () => const MapEntry('', <String, dynamic>{}),
      );
      handler.resolve(
        Response(requestOptions: opts, data: entry.value, statusCode: 200),
      );
    },
  ));
  return dio;
}

const _testUser = {
  'id': 'user-1',
  'name': 'Test User',
  'email': 'test@example.com',
  'phone': '',
  'role': 'RESIDENT',
};

void main() {
  group('AuthNotifier', () {
    late _FakeStorage storage;

    setUp(() => storage = _FakeStorage());

    test('verifyOtp with valid credentials stores access + refresh token', () async {
      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(storage),
        dioProvider.overrideWithValue(_fakeDio({
          '/auth/verify-otp': {
            'accessToken': 'acc-tok',
            'refreshToken': 'ref-tok',
            'role': 'resident',
            'user': _testUser,
            'units': <dynamic>[],
          },
        })),
      ]);
      addTearDown(container.dispose);

      // Build completes (no token → unauthenticated, no /auth/me call)
      await container.read(authProvider.future);

      await container.read(authProvider.notifier).verifyOtp(
        phone: '+9647501234567',
        otp: '123456',
      );

      expect(await storage.getAuthToken(), equals('acc-tok'));
      expect(await storage.getRefreshToken(), equals('ref-tok'));
    });

    test('verifyOtp failure does not store any token', () async {
      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(storage),
        dioProvider.overrideWithValue(_fakeDio({}, failAll: true)),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      await expectLater(
        container.read(authProvider.notifier).verifyOtp(
          phone: '+9647501234567',
          otp: 'bad-otp',
        ),
        throwsA(isA<DioException>()),
      );

      expect(await storage.getAuthToken(), isNull);
    });

    test('logout clears auth token from secure storage', () async {
      await storage.setAuthToken('stale-token');

      final container = ProviderContainer(overrides: [
        secureStorageProvider.overrideWithValue(storage),
        dioProvider.overrideWithValue(_fakeDio({
          '/auth/me': {'user': _testUser, 'units': <dynamic>[]},
          '/auth/logout': <String, dynamic>{},
        })),
      ]);
      addTearDown(container.dispose);

      await container.read(authProvider.future);

      // Should be authenticated now
      expect(container.read(authProvider).value?.status,
          equals(AuthStatus.authenticated));

      await container.read(authProvider.notifier).logout();

      expect(await storage.getAuthToken(), isNull);
      expect(container.read(authProvider).value?.status,
          equals(AuthStatus.unauthenticated));
    });
  });
}
