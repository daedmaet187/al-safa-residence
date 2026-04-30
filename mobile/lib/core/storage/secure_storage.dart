import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAuthToken = 'auth_token';
const _kRefreshToken = 'refresh_token';
const _kUserRole = 'user_role';
const _kActiveUnitId = 'active_unit_id';
const _kHasSeenOnboarding = 'has_seen_onboarding';
const _kHasBiometricSetup = 'has_biometric_setup';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getAuthToken() => _storage.read(key: _kAuthToken);
  Future<void> setAuthToken(String token) =>
      _storage.write(key: _kAuthToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<void> setRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getUserRole() => _storage.read(key: _kUserRole);
  Future<void> setUserRole(String role) =>
      _storage.write(key: _kUserRole, value: role);

  Future<String?> getActiveUnitId() => _storage.read(key: _kActiveUnitId);
  Future<void> setActiveUnitId(String id) =>
      _storage.write(key: _kActiveUnitId, value: id);

  Future<bool> getHasSeenOnboarding() async {
    final v = await _storage.read(key: _kHasSeenOnboarding);
    return v == 'true';
  }
  Future<void> setHasSeenOnboarding() =>
      _storage.write(key: _kHasSeenOnboarding, value: 'true');

  Future<bool> getHasBiometricSetup() async {
    final v = await _storage.read(key: _kHasBiometricSetup);
    return v == 'true';
  }
  Future<void> setHasBiometricSetup() =>
      _storage.write(key: _kHasBiometricSetup, value: 'true');

  Future<void> clearAll() => _storage.deleteAll();
}
