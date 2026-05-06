import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';
import '../../../shared/models/conversation.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(conversationDetailProvider(widget.conversationId).notifier)
          .markRead();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _controller.clear();

    await ref.read(sendMessageProvider.notifier).send(widget.conversationId, text);

    setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final convAsync = ref.watch(conversationDetailProvider(widget.conversationId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Scroll to bottom when messages arrive
    ref.listen(conversationDetailProvider(widget.conversationId), (_, next) {
      if (next is AsyncData) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        title: convAsync.when(
          data: (c) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.subject,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(
                c.status == 'closed' ? 'Closed' : 'Active',
                style: TextStyle(
                  fontSize: 11,
                  color: c.status == 'closed'
                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                      : (isDark ? AppColors.darkSuccess : AppColors.success),
                ),
              ),
            ],
          ),
          loading: () => const Text('Chat'),
          error: (_, __) => const Text('Chat'),
        ),
      ),
      body: convAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load conversation',
              style: Theme.of(context).textTheme.titleSmall),
        ),
        data: (conversation) => Column(
          children: [
            Expanded(
              child: conversation.messages.isEmpty
                  ? Center(
                      child: Text('No messages yet. Say hello!',
                          style: Theme.of(context).textTheme.bodySmall),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: conversation.messages.length,
                      itemBuilder: (ctx, i) =>
                          _MessageBubble(message: conversation.messages[i]),
                    ),
            ),
            if (conversation.status != 'closed')
              _ReplyBar(
                controller: _controller,
                sending: _sending,
                onSend: _send,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: isDark ? AppColors.darkSurface : AppColors.surface,
                child: Center(
                  child: Text(
                    'This conversation is closed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isResident = message.isFromResident;
    final timeFmt = DateFormat('h:mm a');
    final time = message.createdAt.isNotEmpty
        ? timeFmt.format(DateTime.tryParse(message.createdAt) ?? DateTime.now())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isResident ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isResident) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.support_agent_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isResident
                    ? (isDark ? AppColors.darkAccent : AppColors.accent)
                    : (isDark ? AppColors.darkSurface : AppColors.surface),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isResident
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isResident
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: isResident
                    ? null
                    : Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: isResident
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isResident)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isResident
                          ? Colors.white
                          : (isDark ? AppColors.darkText : AppColors.text),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isResident
                          ? Colors.white.withOpacity(0.7)
                          : (isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.border),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).viewInsets.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: TextStyle(
                    color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: sending
                      ? [Colors.grey, Colors.grey]
                      : [AppColors.primary, AppColors.secondary],
                ),
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
