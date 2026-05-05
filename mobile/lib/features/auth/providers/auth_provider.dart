import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/user.dart';
import '../../../shared/models/unit.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final List<ResidenceUnit> units;
  final String? activeUnitId;
  final String actorType;
  final String accessLevel;
  final String? primaryUserId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.units = const [],
    this.activeUnitId,
    this.actorType = 'resident',
    this.accessLevel = 'FULL',
    this.primaryUserId,
  });

  bool get isHouseholdMember => actorType == 'household_member';
  bool get isResident => actorType == 'resident';
  bool get hasFullAccess => accessLevel == 'FULL' || actorType == 'resident';

  ResidenceUnit? get activeUnit {
    if (activeUnitId == null) return units.isEmpty ? null : units.first;
    try {
      return units.firstWhere((u) => u.id == activeUnitId);
    } catch (_) {
      return units.isEmpty ? null : units.first;
    }
  }

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    List<ResidenceUnit>? units,
    String? activeUnitId,
    String? actorType,
    String? accessLevel,
    String? primaryUserId,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        units: units ?? this.units,
        activeUnitId: activeUnitId ?? this.activeUnitId,
        actorType: actorType ?? this.actorType,
        accessLevel: accessLevel ?? this.accessLevel,
        primaryUserId: primaryUserId ?? this.primaryUserId,
      );
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAuthToken();
    if (token == null) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/auth/me');
      final data = resp.data as Map<String, dynamic>;
      final userData = data.containsKey('user')
          ? data['user'] as Map<String, dynamic>
          : data;
      final user = User.fromJson(userData);
      final unitsData = data['units'] as List<dynamic>? ?? [];
      final units = unitsData
          .map((e) => ResidenceUnit.fromJson(e as Map<String, dynamic>))
          .toList();
      final activeUnitId = await storage.getActiveUnitId();
      final actorType = data['actorType'] as String? ?? 'resident';
      final accessLevel = data['accessLevel'] as String? ?? 'FULL';
      final primaryUserId = data['primaryUserId'] as String?;

      await storage.setActorType(actorType);
      await storage.setAccessLevel(accessLevel.toString());
      if (primaryUserId != null) await storage.setPrimaryUserId(primaryUserId);

      return AuthState(
        status: AuthStatus.authenticated,
        user: user,
        units: units,
        activeUnitId: activeUnitId,
        actorType: actorType,
        accessLevel: accessLevel.toString(),
        primaryUserId: primaryUserId,
      );
    } catch (_) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp({required String phone}) async {
    final dio = ref.read(dioProvider);
    await dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<void> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final dio = ref.read(dioProvider);
    final storage = ref.read(secureStorageProvider);

    final resp = await dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });

    final token = resp.data['accessToken'] as String;
    final refreshToken = resp.data['refreshToken'] as String;
    final role = resp.data['role'] as String? ?? 'RESIDENT';
    final actorType = resp.data['actorType'] as String? ?? 'resident';
    final accessLevel = (resp.data['accessLevel'] ?? 'FULL').toString();
    final primaryUserId = resp.data['primaryUserId'] as String?;

    await storage.setAuthToken(token);
    await storage.setRefreshToken(refreshToken);
    await storage.setUserRole(role);
    await storage.setActorType(actorType);
    await storage.setAccessLevel(accessLevel);
    if (primaryUserId != null) await storage.setPrimaryUserId(primaryUserId);

    final user = User.fromJson(resp.data['user'] as Map<String, dynamic>);
    final unitsData = resp.data['units'] as List<dynamic>? ?? [];
    final units = unitsData
        .map((e) => ResidenceUnit.fromJson(e as Map<String, dynamic>))
        .toList();

    state = AsyncData(AuthState(
      status: AuthStatus.authenticated,
      user: user,
      units: units,
      actorType: actorType,
      accessLevel: accessLevel,
      primaryUserId: primaryUserId,
    ));
  }

  Future<void> switchUnit(String unitId) async {
    final storage = ref.read(secureStorageProvider);
    await storage.setActiveUnitId(unitId);
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(activeUnitId: unitId));
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureStorageProvider);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/logout');
    } catch (_) {}
    await storage.clearAll();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
