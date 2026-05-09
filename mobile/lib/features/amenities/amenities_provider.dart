import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/dio_client.dart';
import '../../shared/models/amenity.dart';

final amenitiesProvider = FutureProvider<List<Amenity>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/amenities');
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
      .map((e) => Amenity.fromJson(e as Map<String, dynamic>))
      .toList();
});

final myBookingsProvider = FutureProvider<List<AmenityBooking>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/amenities/my-bookings');
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
      .map((e) => AmenityBooking.fromJson(e as Map<String, dynamic>))
      .toList();
});

class BookingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createBooking({
    required String amenityId,
    required String date,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      await dio.post('/amenities/$amenityId/bookings', data: {
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      ref.invalidate(myBookingsProvider);
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      await dio.delete('/amenities/bookings/$bookingId');
      ref.invalidate(myBookingsProvider);
    });
  }
}

final bookingNotifierProvider =
    AsyncNotifierProvider<BookingNotifier, void>(BookingNotifier.new);
