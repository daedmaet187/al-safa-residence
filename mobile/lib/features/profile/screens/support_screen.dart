import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';

final _supportInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/support/info');
  return resp.data as Map<String, dynamic>;
});

const _staticContact = {
  'phone': '+964 770 000 0000',
  'email': 'support@al-safa-residence.iq',
  'workingHours': 'Sun–Thu, 8:00 AM – 6:00 PM',
};

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(_supportInfoProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _SupportBody(
          contact: _staticContact,
          faq: const [],
          isDark: isDark,
          errorMessage: 'Could not load FAQ. Please try again later.',
        ),
        data: (info) => _SupportBody(
          contact: (info['contact'] as Map<String, dynamic>?) ?? _staticContact,
          faq: (info['faq'] as List<dynamic>? ?? [])
              .map((e) => e as Map<String, dynamic>)
              .toList(),
          isDark: isDark,
        ),
      ),
    );
  }
}

class _SupportBody extends StatelessWidget {
  const _SupportBody({
    required this.contact,
    required this.faq,
    required this.isDark,
    this.errorMessage,
  });

  final Map<String, dynamic> contact;
  final List<Map<String, dynamic>> faq;
  final bool isDark;
  final String? errorMessage;

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $value'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = contact['phone'] as String? ?? '';
    final email = contact['email'] as String? ?? '';
    final hours = contact['workingHours'] as String? ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contact Management',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: phone,
                onTap: phone.isNotEmpty ? () => _copy(context, phone) : null,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.email_outlined,
                label: email,
                onTap: email.isNotEmpty ? () => _copy(context, email) : null,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: hours,
                isDark: isDark,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              errorMessage!,
              style: TextStyle(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted),
            ),
          ),
        ],
        if (faq.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...faq.map((item) => _FaqItem(
                question: item['question'] as String? ?? '',
                answer: item['answer'] as String? ?? '',
                isDark: isDark,
              )),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.isDark,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isDark ? AppColors.darkPrimary : AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            if (onTap != null)
              Icon(Icons.copy_outlined,
                  size: 14,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.isDark,
  });
  final String question;
  final String answer;
  final bool isDark;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: ExpansionTile(
        title:
            Text(widget.question, style: Theme.of(context).textTheme.titleSmall),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.isDark
                      ? AppColors.darkTextMuted
                      : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
