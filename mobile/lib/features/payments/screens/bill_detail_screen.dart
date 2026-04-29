import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/payments_provider.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/gold_button.dart';

class BillDetailScreen extends ConsumerWidget {
  const BillDetailScreen({super.key, required this.billId});
  final String billId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billAsync = ref.watch(billDetailProvider(billId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt = NumberFormat.currency(symbol: 'AED ', decimalDigits: 2);
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Details')),
      body: billAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bill) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(bill.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18)),
                        StatusChip(status: bill.status.name, inverted: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFmt.format(bill.amount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${dateFmt.format(bill.dueDate)}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Line items
              if (bill.lineItems.isNotEmpty) ...[
                Text('Breakdown',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color:
                            isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ...bill.lineItems.map((item) => ListTile(
                            title: Text(item.label),
                            trailing: Text(
                              currencyFmt.format(item.amount),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          )),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        trailing: Text(
                          currencyFmt.format(bill.amount),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Pay button
              if (bill.status != BillStatus.paid)
                GoldButton(
                  label: 'Pay Now',
                  icon: Icons.payment_rounded,
                  onPressed: () => context.push('/home/payments/${bill.id}/pay'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
