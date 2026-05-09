import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/amenity.dart';
import '../amenities_provider.dart';

class AmenitiesScreen extends ConsumerWidget {
  const AmenitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amenitiesAsync = ref.watch(amenitiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amenities'),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
        foregroundColor: isDark ? AppColors.darkText : AppColors.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      body: amenitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
              const SizedBox(height: 12),
              Text('Could not load amenities',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(amenitiesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (amenities) {
          if (amenities.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.apartment,
                      size: 56,
                      color:
                          isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
                  const SizedBox(height: 12),
                  Text('No amenities available',
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: amenities.length,
            itemBuilder: (ctx, i) => _AmenityCard(amenity: amenities[i]),
          );
        },
      ),
    );
  }
}

class _AmenityCard extends StatelessWidget {
  const _AmenityCard({required this.amenity});
  final Amenity amenity;

  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('pool') || n.contains('swim')) return Icons.pool;
    if (n.contains('gym') ||
        n.contains('fitness') ||
        n.contains('workout')) return Icons.fitness_center;
    if (n.contains('meeting') ||
        n.contains('conference') ||
        n.contains('room')) return Icons.meeting_room;
    if (n.contains('bbq') ||
        n.contains('grill') ||
        n.contains('outdoor')) return Icons.outdoor_grill;
    return Icons.apartment;
  }

  LinearGradient _gradientFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('pool') || n.contains('swim')) {
      return const LinearGradient(
          colors: [Color(0xFF0369A1), Color(0xFF075985)]);
    }
    if (n.contains('gym') || n.contains('fitness')) {
      return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]);
    }
    if (n.contains('meeting') || n.contains('conference')) {
      return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF047857)]);
    }
    if (n.contains('bbq') || n.contains('grill')) {
      return const LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)]);
    }
    return const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary]);
  }

  String? _hoursSnippet(Map<String, String>? hours) {
    if (hours == null || hours.isEmpty) return null;
    final entry = hours.entries.first;
    return '${entry.key}: ${entry.value}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hoursSnippet = _hoursSnippet(amenity.operatingHours);

    return GestureDetector(
      onTap: () => context.push('/home/amenities/${amenity.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _gradientFor(amenity.name),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(amenity.name),
                    color: Colors.white, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                amenity.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (amenity.location != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceRaised
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    amenity.location!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.people_outline,
                      size: 14,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${amenity.capacity}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted,
                        ),
                  ),
                ],
              ),
              if (hoursSnippet != null) ...[
                const SizedBox(height: 4),
                Text(
                  hoursSnippet,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSubtle
                            : AppColors.textSubtle,
                        fontSize: 10,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
