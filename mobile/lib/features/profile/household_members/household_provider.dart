import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/household_member.dart';

class HouseholdState {
  final List<HouseholdMember> members;
  final bool isLoading;
  final String? error;

  const HouseholdState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  HouseholdState copyWith({
    List<HouseholdMember>? members,
    bool? isLoading,
    String? error,
  }) =>
      HouseholdState(
        members: members ?? this.members,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class HouseholdNotifier extends AsyncNotifier<HouseholdState> {
  @override
  Future<HouseholdState> build() async {
    return _fetch();
  }

  Future<HouseholdState> _fetch() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/household/members');
    final data = resp.data as Map<String, dynamic>;
    final list = (data['members'] as List<dynamic>? ?? [])
        .map((e) => HouseholdMember.fromJson(e as Map<String, dynamic>))
        .toList();
    return HouseholdState(members: list);
  }

  Future<void> fetchMembers() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> addMember({
    required String name,
    required String phone,
    required String relationship,
    required HouseholdAccess accessLevel,
  }) async {
    final dio = ref.read(dioProvider);
    await dio.post('/household/members', data: {
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'accessLevel': accessLevel == HouseholdAccess.full ? 'FULL' : 'LIMITED',
    });
    await fetchMembers();
  }

  Future<void> updateMember({
    required String memberId,
    String? name,
    String? relationship,
    HouseholdAccess? accessLevel,
  }) async {
    final dio = ref.read(dioProvider);
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (relationship != null) body['relationship'] = relationship;
    if (accessLevel != null) {
      body['accessLevel'] =
          accessLevel == HouseholdAccess.full ? 'FULL' : 'LIMITED';
    }
    await dio.patch('/household/members/$memberId', data: body);
    await fetchMembers();
  }

  Future<void> removeMember(String memberId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/household/members/$memberId');
    await fetchMembers();
  }
}

final householdProvider =
    AsyncNotifierProvider<HouseholdNotifier, HouseholdState>(
  HouseholdNotifier.new,
);
