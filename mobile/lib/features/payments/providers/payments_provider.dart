import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

enum BillStatus { pending, paid, overdue }

class Bill {
  final String id;
  final String title;
  final String type;
  final double amount;
  final BillStatus status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final List<BillLineItem> lineItems;

  const Bill({
    required this.id,
    required this.title,
    required this.type,
    required this.amount,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.lineItems = const [],
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = BillStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => BillStatus.pending,
    );
    return Bill(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String? ?? 'service',
      amount: (json['amount'] as num).toDouble(),
      status: status,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      lineItems: (json['lineItems'] as List<dynamic>?)
              ?.map((e) => BillLineItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class BillLineItem {
  final String label;
  final double amount;

  const BillLineItem({required this.label, required this.amount});

  factory BillLineItem.fromJson(Map<String, dynamic> json) => BillLineItem(
        label: json['label'] as String,
        amount: (json['amount'] as num).toDouble(),
      );
}

// ---------- Providers ----------

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/bills');
  final list = response.data as List<dynamic>;
  return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
});

final billDetailProvider =
    FutureProvider.family<Bill, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/bills/$id');
  return Bill.fromJson(response.data as Map<String, dynamic>);
});

final paymentHistoryProvider = FutureProvider<List<Bill>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/bills?status=paid');
  final list = response.data as List<dynamic>;
  return list.map((e) => Bill.fromJson(e as Map<String, dynamic>)).toList();
});

class PaymentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> payBill({
    required String billId,
    required String method,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      await dio.post('/bills/$billId/pay', data: {'method': method});
      ref.invalidate(billsProvider);
    });
  }
}

final paymentNotifierProvider =
    AsyncNotifierProvider<PaymentNotifier, void>(PaymentNotifier.new);
