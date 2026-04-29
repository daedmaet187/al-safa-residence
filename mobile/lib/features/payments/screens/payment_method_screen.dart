import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/payments_provider.dart';
import '../../../shared/widgets/gold_button.dart';

class PaymentMethodScreen extends ConsumerStatefulWidget {
  const PaymentMethodScreen({super.key, required this.billId});
  final String billId;

  @override
  ConsumerState<PaymentMethodScreen> createState() =>
      _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends ConsumerState<PaymentMethodScreen> {
  String _selected = 'bank_transfer';

  static const _methods = [
    _PayMethod(
        id: 'bank_transfer',
        label: 'Bank Transfer',
        subtitle: 'Transfer to building account',
        icon: Icons.account_balance_rounded),
    _PayMethod(
        id: 'card',
        label: 'Credit / Debit Card',
        subtitle: 'Visa, Mastercard, Amex',
        icon: Icons.credit_card_rounded),
    _PayMethod(
        id: 'cash',
        label: 'Cash at Office',
        subtitle: 'Pay at management office',
        icon: Icons.payments_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment Method')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose how you\'d like to pay',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.textMuted)),
            const SizedBox(height: 20),
            ...List.generate(_methods.length, (i) {
              final m = _methods[i];
              final isSelected = _selected == m.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selected = m.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.darkPrimaryLight
                              : AppColors.primaryLight)
                          : (isDark
                              ? AppColors.darkSurface
                              : AppColors.surface),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary)
                            : (isDark
                                ? AppColors.darkBorder
                                : AppColors.border),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.primary)
                                : (isDark
                                    ? AppColors.darkSurfaceRaised
                                    : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            m.icon,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                          color: isSelected
                                              ? (isDark
                                                  ? AppColors.darkPrimary
                                                  : AppColors.primary)
                                              : null)),
                              Text(m.subtitle,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded,
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            GoldButton(
              label: 'Confirm Payment',
              icon: Icons.check_rounded,
              isLoading: paymentState.isLoading,
              onPressed: () async {
                await ref
                    .read(paymentNotifierProvider.notifier)
                    .payBill(billId: widget.billId, method: _selected);
                if (context.mounted) {
                  context.go('/home/payments');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment recorded!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PayMethod {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  const _PayMethod(
      {required this.id,
      required this.label,
      required this.subtitle,
      required this.icon});
}
