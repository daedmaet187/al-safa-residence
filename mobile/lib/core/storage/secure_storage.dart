import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAuthToken = 'auth_token';
const _kRefreshToken = 'refresh_token';
const _kUserRole = 'user_role';
const _kActiveUnitId = 'active_unit_id';
const _kHasSeenOnboarding = 'has_seen_onboarding';
const _kHasBiometricSetup = 'has_biometric_setup';
const _kActorType = 'actor_type';
const _kAccessLevel = 'access_level';
const _kPrimaryUserId = 'primary_user_id';

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

  Future<String?> getActorType() => _storage.read(key: _kActorType);
  Future<void> setActorType(String v) => _storage.write(key: _kActorType, value: v);

  Future<String?> getAccessLevel() => _storage.read(key: _kAccessLevel);
  Future<void> setAccessLevel(String v) => _storage.write(key: _kAccessLevel, value: v);

  Future<String?> getPrimaryUserId() => _storage.read(key: _kPrimaryUserId);
  Future<void> setPrimaryUserId(String id) => _storage.write(key: _kPrimaryUserId, value: id);

  Future<bool> getHasBiometricSetup() async {
    final v = await _storage.read(key: _kHasBiometricSetup);
    return v == 'true';
  }
  Future<void> setHasBiometricSetup() =>
      _storage.write(key: _kHasBiometricSetup, value: 'true');

  Future<void> clearAll() async {
    // Preserve onboarding + biometric flags across logouts
    final seen = await _storage.read(key: _kHasSeenOnboarding);
    final bio = await _storage.read(key: _kHasBiometricSetup);
    await _storage.deleteAll();
    if (seen != null) await _storage.write(key: _kHasSeenOnboarding, value: seen);
    if (bio != null) await _storage.write(key: _kHasBiometricSetup, value: bio);
  }
}
