import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/unit.dart';

class UnitStats {
  final int monthsInResidence;
  final double totalPaid;
  final int openMaintenanceRequests;

  const UnitStats({
    required this.monthsInResidence,
    required this.totalPaid,
    required this.openMaintenanceRequests,
  });
}

class UnitDetail {
  final ResidenceUnit unit;
  final UnitStats stats;
  final List<UnitDocument> documents;

  const UnitDetail(
      {required this.unit, required this.stats, required this.documents});
}

class UnitDocument {
  final String id;
  final String name;
  final String type;
  final String? url;

  const UnitDocument(
      {required this.id,
      required this.name,
      required this.type,
      this.url});
}

final unitDetailProvider = FutureProvider<UnitDetail>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/units/my-unit');
  final data = response.data as Map<String, dynamic>;

  final unit =
      ResidenceUnit.fromJson(data['unit'] as Map<String, dynamic>);
  final statsData = data['stats'] as Map<String, dynamic>? ?? {};
  final stats = UnitStats(
    monthsInResidence: (statsData['monthsInResidence'] as num?)?.toInt() ?? 0,
    totalPaid: (statsData['totalPaid'] as num?)?.toDouble() ?? 0,
    openMaintenanceRequests:
        (statsData['openMaintenanceRequests'] as num?)?.toInt() ?? 0,
  );
  final docs = (data['documents'] as List<dynamic>?)
          ?.map((e) {
            final m = e as Map<String, dynamic>;
            return UnitDocument(
              id: m['id'] as String,
              name: m['name'] as String,
              type: m['type'] as String? ?? 'document',
              url: m['url'] as String?,
            );
          })
          .toList() ??
      [];

  return UnitDetail(unit: unit, stats: stats, documents: docs);
});
