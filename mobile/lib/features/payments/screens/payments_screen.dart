import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/payments_provider.dart';
import '../../../shared/widgets/status_chip.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'History',
            onPressed: () => context.push('/home/payments/history'),
          ),
        ],
      ),
      body: billsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextSubtle
                          : AppColors.textSubtle),
                  const SizedBox(height: 16),
                  Text('No bills',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('You are all caught up!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.textMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final bill = bills[i];
              return _BillCard(bill: bill);
            },
          );
        },
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.bill});
  final Bill bill;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt =
        NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    Color borderColor =
        isDark ? AppColors.darkBorder : AppColors.border;
    if (bill.status == BillStatus.overdue) {
      borderColor =
          (isDark ? AppColors.darkDanger : AppColors.danger).withOpacity(0.4);
    }

    final isPending = bill.status == BillStatus.pending || bill.status == BillStatus.overdue;

    return GestureDetector(
      onTap: () => context.push('/home/payments/${bill.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimaryLight
                        : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconFor(bill.type),
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'Due ${dateFmt.format(bill.dueDate)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: bill.status == BillStatus.overdue
                              ? (isDark ? AppColors.darkDanger : AppColors.danger)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFmt.format(bill.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    StatusChip(status: bill.status.name),
                  ],
                ),
              ],
            ),
            if (isPending) ...[  
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/home/payments/${bill.id}/pay'),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Pay Now'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor:
                        bill.status == BillStatus.overdue
                            ? (isDark ? AppColors.darkDanger : AppColors.danger)
                            : (isDark ? AppColors.darkPrimary : AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type.toLowerCase()) {
      case 'service':
        return Icons.home_repair_service_rounded;
      case 'utility':
        return Icons.bolt_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }
}
