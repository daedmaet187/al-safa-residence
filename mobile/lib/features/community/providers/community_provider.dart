import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/announcement.dart';

final announcementsProvider =
    FutureProvider<List<Announcement>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/announcements');
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
      .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
      .toList();
});

final announcementDetailProvider =
    FutureProvider.family<Announcement, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/announcements/$id');
  return Announcement.fromJson(response.data as Map<String, dynamic>);
});
