import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/conversation.dart';

// ── Conversations list (polls every 10s) ────────────────────────────────────

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  Timer? _timer;

  @override
  Future<List<Conversation>> build() async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling();
    return _fetch();
  }

  Future<List<Conversation>> _fetch() async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/chat/conversations');
    final raw = response.data;
    final List<dynamic> list;
    if (raw is Map<String, dynamic> && raw.containsKey('data')) {
      list = raw['data'] as List<dynamic>;
    } else if (raw is List<dynamic>) {
      list = raw;
    } else {
      list = [];
    }
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final updated = await _fetch();
        if (state is AsyncData) state = AsyncData(updated);
      } catch (_) {}
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
        ConversationsNotifier.new);

// ── Single conversation with messages (polls every 10s) ─────────────────────

class ConversationDetailNotifier
    extends FamilyAsyncNotifier<Conversation, String> {
  Timer? _timer;

  @override
  Future<Conversation> build(String conversationId) async {
    ref.onDispose(() => _timer?.cancel());
    _startPolling(conversationId);
    return _fetch(conversationId);
  }

  Future<Conversation> _fetch(String id) async {
    final dio = ref.read(dioProvider);
    final response = await dio.get('/chat/conversations/$id');
    return Conversation.fromJson(response.data as Map<String, dynamic>);
  }

  void _startPolling(String id) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final updated = await _fetch(id);
        if (state is AsyncData) state = AsyncData(updated);
      } catch (_) {}
    });
  }

  Future<void> markRead() async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/chat/conversations/$arg/read');
    } catch (_) {}
  }
}

final conversationDetailProvider =
    AsyncNotifierProvider.family<ConversationDetailNotifier, Conversation, String>(
        ConversationDetailNotifier.new);

// ── Send message ─────────────────────────────────────────────────────────────

class SendMessageNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send(String conversationId, String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      await dio.post('/chat/conversations/$conversationId/messages',
          data: {'content': content});
      ref.invalidate(conversationDetailProvider(conversationId));
      ref.invalidate(conversationsProvider);
    });
  }
}

final sendMessageProvider =
    AsyncNotifierProvider<SendMessageNotifier, void>(SendMessageNotifier.new);

// ── Create conversation ──────────────────────────────────────────────────────

class CreateConversationNotifier extends AsyncNotifier<Conversation?> {
  @override
  Future<Conversation?> build() async => null;

  Future<Conversation?> create(String subject) async {
    state = const AsyncLoading();
    Conversation? result;
    state = await AsyncValue.guard(() async {
      final dio = ref.read(dioProvider);
      final response =
          await dio.post('/chat/conversations', data: {'subject': subject});
      result = Conversation.fromJson(response.data as Map<String, dynamic>);
      ref.invalidate(conversationsProvider);
      return result;
    });
    return result;
  }
}

final createConversationProvider =
    AsyncNotifierProvider<CreateConversationNotifier, Conversation?>(
        CreateConversationNotifier.new);
