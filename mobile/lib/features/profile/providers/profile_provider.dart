import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/user.dart';

class ProfileNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/profile');
    return User.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final resp = await dio.patch('/profile', data: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      });
      return User.fromJson(resp.data as Map<String, dynamic>);
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post('/profile/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, User?>(ProfileNotifier.new);
