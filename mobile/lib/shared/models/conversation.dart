class Conversation {
  final String id;
  final String subject;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<Message> messages;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.subject,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        subject: json['subject'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        createdAt: json['createdAt'] as String? ?? '',
        updatedAt: json['updatedAt'] as String? ?? '',
        messages: (json['messages'] as List<dynamic>?)
                ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        unreadCount: json['unreadCount'] as int? ?? 0,
      );

  Message? get lastMessage => messages.isNotEmpty ? messages.last : null;
}

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderType;
  final String content;
  final bool isRead;
  final String createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'] as String,
        conversationId: json['conversationId'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        senderType: json['senderType'] as String? ?? 'resident',
        content: json['content'] as String? ?? '',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: json['createdAt'] as String? ?? '',
      );

  bool get isFromResident => senderType == 'resident';
  bool get isFromAdmin => senderType == 'admin';
}
