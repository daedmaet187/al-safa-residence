import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/payments_provider.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(paymentHistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color: isDark
                          ? AppColors.darkTextSubtle
                          : AppColors.textSubtle),
                  const SizedBox(height: 16),
                  Text('No payment history',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bills.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final bill = bills[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSuccessLight
                        : AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle_outline_rounded,
                      color: isDark
                          ? AppColors.darkSuccess
                          : AppColors.success,
                      size: 22),
                ),
                title: Text(bill.title,
                    style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(
                  bill.paidAt != null
                      ? 'Paid ${dateFmt.format(bill.paidAt!)}'
                      : 'Paid',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  currencyFmt.format(bill.amount),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isDark ? AppColors.darkSuccess : AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
