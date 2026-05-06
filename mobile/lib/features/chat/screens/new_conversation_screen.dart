import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final subject = _subjectController.text.trim();
    final firstMessage = _messageController.text.trim();

    final conversation =
        await ref.read(createConversationProvider.notifier).create(subject);

    if (conversation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start conversation. Please try again.')),
        );
      }
      return;
    }

    // Send the first message if provided
    if (firstMessage.isNotEmpty) {
      await ref
          .read(sendMessageProvider.notifier)
          .send(conversation.id, firstMessage);
    }

    if (mounted) {
      context.pushReplacement('/home/chat/${conversation.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final createAsync = ref.watch(createConversationProvider);
    final isLoading = createAsync is AsyncLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Start a new support conversation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Describe your issue and our team will respond shortly.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Text('Subject', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'e.g. Maintenance follow-up, Billing question…',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 1.5),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Subject is required';
                if (v.trim().length < 3) return 'Subject is too short';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Text('First Message (optional)',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: 'Describe your issue in detail…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Start Conversation',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
