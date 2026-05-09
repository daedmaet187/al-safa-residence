import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/amenity.dart';
import '../amenities_provider.dart';
import 'booking_sheet.dart';

class AmenityDetailScreen extends ConsumerWidget {
  const AmenityDetailScreen({super.key, required this.amenityId});
  final String amenityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenitiesAsync = ref.watch(amenitiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return amenitiesAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load amenity'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(amenitiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (amenities) {
        final amenity = amenities.where((a) => a.id == amenityId).firstOrNull;
        if (amenity == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Amenity')),
            body: const Center(child: Text('Amenity not found')),
          );
        }
        return _AmenityDetailView(amenity: amenity, isDark: isDark);
      },
    );
  }
}

class _AmenityDetailView extends ConsumerWidget {
  const _AmenityDetailView({required this.amenity, required this.isDark});
  final Amenity amenity;
  final bool isDark;

  void _openBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingSheet(
        amenityId: amenity.id,
        amenityName: amenity.name,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final myBookings = bookingsAsync.valueOrNull
            ?.where((b) => b.amenityId == amenity.id)
            .toList() ??
        [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                amenity.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [AppColors.darkSurface, AppColors.darkSurfaceRaised]
                        : [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.apartment,
                      size: 64, color: Colors.white38),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _InfoCard(amenity: amenity, isDark: isDark),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: () => _openBookingSheet(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Book Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('My Bookings',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (myBookings.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceRaised
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 40,
                              color: isDark
                                  ? AppColors.darkTextSubtle
                                  : AppColors.textSubtle),
                          const SizedBox(height: 8),
                          Text('No bookings yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted,
                                  )),
                        ],
                      ),
                    ),
                  )
                else
                  ...myBookings.map((b) =>
                      _MiniBookingItem(booking: b, isDark: isDark)),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.amenity, required this.isDark});
  final Amenity amenity;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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
          if (amenity.description != null) ...[
            Text(amenity.description!,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 14),
            Divider(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                height: 1),
            const SizedBox(height: 14),
          ],
          _InfoRow(
            icon: Icons.people_outline,
            label: 'Capacity',
            value: '${amenity.capacity} people',
            isDark: isDark,
          ),
          if (amenity.location != null) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: amenity.location!,
              isDark: isDark,
            ),
          ],
          if (amenity.operatingHours != null &&
              amenity.operatingHours!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                height: 1),
            const SizedBox(height: 14),
            Text('Operating Hours',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted,
                    )),
            const SizedBox(height: 8),
            ...amenity.operatingHours!.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(e.key,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    Text(e.value,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: isDark ? AppColors.darkTextMuted : AppColors.textMuted),
        const SizedBox(width: 10),
        Text('$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                )),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _MiniBookingItem extends StatelessWidget {
  const _MiniBookingItem({required this.booking, required this.isDark});
  final AmenityBooking booking;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'confirmed':
        statusColor = isDark ? AppColors.darkSuccess : AppColors.success;
        statusBg =
            isDark ? AppColors.darkSuccessLight : AppColors.successLight;
        break;
      case 'cancelled':
        statusColor = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
        statusBg = isDark ? AppColors.darkSurfaceRaised : AppColors.background;
        break;
      default:
        statusColor = isDark ? AppColors.darkWarning : AppColors.warning;
        statusBg = isDark ? AppColors.darkWarningLight : AppColors.warningLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.date}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.startTime} – ${booking.endTime}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
