class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    this.fileUrl,
    required this.sentAt,
    required this.edited,
    this.readAt,
    required this.isRead,
  });

  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final String type;
  final String? fileUrl;
  final DateTime sentAt;
  final bool edited;
  final DateTime? readAt;
  final bool isRead;

  ChatMessage copyWith({
    int? id,
    int? chatId,
    int? senderId,
    String? content,
    String? type,
    String? fileUrl,
    DateTime? sentAt,
    bool? edited,
    DateTime? readAt,
    bool? isRead,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      sentAt: sentAt ?? this.sentAt,
      edited: edited ?? this.edited,
      readAt: readAt ?? this.readAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
