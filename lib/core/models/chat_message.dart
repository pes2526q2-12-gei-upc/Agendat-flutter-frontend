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
  });

  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final String type;
  final String? fileUrl;
  final DateTime sentAt;
  final bool edited;
}
