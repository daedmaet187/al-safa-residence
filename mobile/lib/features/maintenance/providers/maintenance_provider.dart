import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class MaintenanceRequest {
  final String id;
  final String title;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> photoUrls;
  final String? adminNote;
  final List<StatusEvent> timeline;

  const MaintenanceRequest({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.photoUrls = const [],
    this.adminNote,
    this.timeline = const [],
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) =>
      MaintenanceRequest(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String? ?? 'general',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : null,
        photoUrls: (json['photoUrls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        adminNote: json['adminNote'] as String?,
        timeline: (json['timeline'] as List<dynamic>?)
                ?.map((e) => StatusEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

class StatusEvent {
  final String status;
  final String? note;
  final DateTime createdAt;

  const StatusEvent(
      {required this.status, this.note, required this.createdAt});

  factory StatusEvent.fromJson(Map<String, dynamic> json) => StatusEvent(
        status: json['status'] as String,
        note: json['note'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

final maintenanceRequestsProvider =
    FutureProvider<List<MaintenanceRequest>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/maintenance');
  // API returns {count, data:[]} or a flat list
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
      .map((e) => MaintenanceRequest.fromJson(e as Map<String, dynamic>))
      .toList();
});

final maintenanceDetailProvider =
    FutureProvider.family<MaintenanceRequest, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/maintenance/$id');
  return MaintenanceRequest.fromJson(response.data as Map<String, dynamic>);
});

class MaintenanceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createRequest({
    required String title,
    required String category,
    required String description,
    required List<String> photoUrls,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      // Get unitId from auth state
      final authState = ref.read(authProvider).value;
      final unitId = authState?.activeUnit?.id ?? '';
      await dio.post('/maintenance', data: {
        'title': title,
        'category': category,
        'description': description,
        'photoUrls': photoUrls,
        if (unitId.isNotEmpty) 'unitId': unitId,
      });
      ref.invalidate(maintenanceRequestsProvider);
    });
  }
}

final maintenanceNotifierProvider =
    AsyncNotifierProvider<MaintenanceNotifier, void>(MaintenanceNotifier.new);
