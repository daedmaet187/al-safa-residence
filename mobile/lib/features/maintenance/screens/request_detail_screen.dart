import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/status_chip.dart';
import '../providers/maintenance_provider.dart';

Widget _photoPlaceholder(bool isDark) => Container(
  width: 100, height: 100,
  decoration: BoxDecoration(
    color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
    borderRadius: BorderRadius.circular(10),
  ),
  child: Icon(Icons.image_outlined,
      color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle, size: 32),
);

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(maintenanceDetailProvider(requestId));
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (request) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(request.title,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const SizedBox(width: 12),
                  StatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceRaised
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(request.category,
                        style: Theme.of(context).textTheme.labelSmall),
                  ),
                  const SizedBox(width: 8),
                  Text(dateFmt.format(request.createdAt),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              if (request.description.isNotEmpty) ...[
                Text('Description',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border),
                  ),
                  child: Text(request.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
                const SizedBox(height: 20),
              ],

              // Photos
              if (request.photoUrls.isNotEmpty) ...[
                Text('Attached Photos',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: request.photoUrls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final url = request.photoUrls[i];
                      final isRemote = url.startsWith('http');
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: isRemote
                            ? Image.network(url, width: 100, height: 100, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _photoPlaceholder(isDark))
                            : _photoPlaceholder(isDark),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Admin note
              if (request.adminNote != null && request.adminNote!.isNotEmpty) ...[
                Text('Admin Note',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryLight
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkPrimary.withOpacity(0.3)
                          : AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.admin_panel_settings_outlined,
                          size: 18,
                          color:
                              isDark ? AppColors.darkPrimary : AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(request.adminNote!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Timeline
              if (request.timeline.isNotEmpty) ...[
                Text('Status Timeline',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                ...List.generate(request.timeline.length, (i) {
                  final event = request.timeline[i];
                  final isLast = i == request.timeline.length - 1;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: isLast
                                    ? (isDark
                                        ? AppColors.darkAccent
                                        : AppColors.accent)
                                    : (isDark
                                        ? AppColors.darkBorder
                                        : AppColors.border),
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StatusChip(status: event.status),
                                if (event.note != null) ...[
                                  const SizedBox(height: 4),
                                  Text(event.note!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                ],
                                const SizedBox(height: 2),
                                Text(
                                  dateFmt.format(event.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
