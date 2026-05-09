import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/amenity.dart';
import '../amenities_provider.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
          foregroundColor: isDark ? AppColors.darkText : AppColors.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: TabBar(
            labelColor: isDark ? AppColors.darkAccent : AppColors.accent,
            unselectedLabelColor:
                isDark ? AppColors.darkTextMuted : AppColors.textMuted,
            indicatorColor: isDark ? AppColors.darkAccent : AppColors.accent,
            dividerColor: isDark ? AppColors.darkBorder : AppColors.border,
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsList(upcoming: true),
            _BookingsList(upcoming: false),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends ConsumerWidget {
  const _BookingsList({required this.upcoming});
  final bool upcoming;

  bool _isUpcoming(AmenityBooking b) {
    if (b.status == 'cancelled') return false;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    try {
      final parts = b.date.split('-');
      final bookingDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return !bookingDate.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load bookings',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(myBookingsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (all) {
        final bookings =
            all.where((b) => upcoming ? _isUpcoming(b) : !_isUpcoming(b)).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(myBookingsProvider),
          child: bookings.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 48,
                                color: isDark
                                    ? AppColors.darkTextSubtle
                                    : AppColors.textSubtle),
                            const SizedBox(height: 12),
                            Text(
                              upcoming
                                  ? 'No upcoming bookings'
                                  : 'No past bookings',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) =>
                      _BookingItem(booking: bookings[i], ref: ref),
                ),
        );
      },
    );
  }
}

class _BookingItem extends StatelessWidget {
  const _BookingItem({required this.booking, required this.ref});
  final AmenityBooking booking;
  final WidgetRef ref;

  bool get _isFuture {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    try {
      final parts = booking.date.split('-');
      final bookingDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return !bookingDate.isBefore(todayDate);
    } catch (_) {
      return false;
    }
  }

  bool get _canCancel =>
      (booking.status == 'pending' || booking.status == 'confirmed') &&
      _isFuture;

  Color _statusColor(String status, bool isDark) {
    switch (status) {
      case 'confirmed':
        return isDark ? AppColors.darkSuccess : AppColors.success;
      case 'cancelled':
        return isDark ? AppColors.darkTextMuted : AppColors.textMuted;
      default:
        return isDark ? AppColors.darkWarning : AppColors.warning;
    }
  }

  Color _statusBg(String status, bool isDark) {
    switch (status) {
      case 'confirmed':
        return isDark ? AppColors.darkSuccessLight : AppColors.successLight;
      case 'cancelled':
        return isDark ? AppColors.darkSurfaceRaised : AppColors.background;
      default:
        return isDark ? AppColors.darkWarningLight : AppColors.warningLight;
    }
  }

  void _cancel(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel Booking')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(bookingNotifierProvider.notifier)
        .cancelBooking(booking.id);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = booking.status;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.amenityName ?? 'Amenity',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(status, isDark),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: _statusColor(status, isDark),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14,
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                booking.date,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_outlined,
                  size: 14,
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                '${booking.startTime} – ${booking.endTime}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (_canCancel) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _cancel(context),
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? AppColors.darkDanger : AppColors.danger,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Cancel',
                    style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
