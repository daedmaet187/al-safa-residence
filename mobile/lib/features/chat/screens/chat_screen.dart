import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/chat/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_comment_rounded),
        label: const Text('New Chat'),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: isDark ? AppColors.darkDanger : AppColors.danger),
              const SizedBox(height: 12),
              Text('Could not load conversations',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(conversationsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 64,
                      color: isDark ? AppColors.darkTextSubtle : AppColors.textSubtle),
                  const SizedBox(height: 16),
                  Text('No conversations yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap the button below to start a new chat',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final conv = conversations[i];
              final last = conv.lastMessage;
              final isClosed = conv.status == 'closed';
              final dateFmt = DateFormat('MMM d');

              return InkWell(
                onTap: () => context.push('/home/chat/${conv.id}'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isClosed
                              ? (isDark ? AppColors.darkSurfaceRaised : AppColors.background)
                              : (isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isClosed
                              ? Icons.lock_outline_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 22,
                          color: isClosed
                              ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                              : (isDark ? AppColors.darkPrimary : AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    conv.subject,
                                    style: Theme.of(context).textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (conv.unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkAccent : AppColors.accent,
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      '${conv.unreadCount}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            if (last != null)
                              Text(
                                last.content,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (conv.updatedAt.isNotEmpty)
                            Text(
                              dateFmt.format(DateTime.tryParse(conv.updatedAt) ??
                                  DateTime.now()),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? (isDark
                                      ? AppColors.darkSurfaceRaised
                                      : AppColors.background)
                                  : (isDark
                                      ? AppColors.darkSuccessLight
                                      : AppColors.successLight),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              conv.status,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: isClosed
                                    ? (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.textMuted)
                                    : (isDark
                                        ? AppColors.darkSuccess
                                        : AppColors.success),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
