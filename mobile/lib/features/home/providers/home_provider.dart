import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/announcement.dart';

class HomeSummary {
  final List<Announcement> recentAnnouncements;
  final int activeGuestPasses;
  final int overdueBills;
  final int openMaintenanceRequests;

  const HomeSummary({
    this.recentAnnouncements = const [],
    this.activeGuestPasses = 0,
    this.overdueBills = 0,
    this.openMaintenanceRequests = 0,
  });
}

final homeSummaryProvider = FutureProvider<HomeSummary>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/dashboard/summary');
  final data = response.data as Map<String, dynamic>;

  final announcements = (data['recentAnnouncements'] as List<dynamic>? ?? [])
      .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
      .take(3)
      .toList();

  return HomeSummary(
    recentAnnouncements: announcements,
    activeGuestPasses: (data['activeGuestPasses'] as num?)?.toInt() ?? 0,
    overdueBills: (data['overdueBills'] as num?)?.toInt() ?? 0,
    openMaintenanceRequests:
        (data['openMaintenanceRequests'] as num?)?.toInt() ?? 0,
  );
});
