class MessageDto {
  const MessageDto({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.fileUrl,
    required this.sentAt,
    required this.edited,
  });

  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final String type;
  final String? fileUrl;
  final String sentAt;
  final bool edited;

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: ((json['id_message'] ?? json['id']) as num).toInt(),
      chatId: _parseNestedId(json['chat']),
      senderId: _parseNestedId(json['sender']),
      content: (json['content'] ?? '').toString().trim(),
      type: (json['type'] ?? 'text').toString().trim().toLowerCase(),
      fileUrl: _trimOrNull(json['file_url']),
      sentAt: (json['sent_at'] ?? '').toString().trim(),
      edited: json['edited'] == true,
    );
  }

  static int _parseNestedId(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is Map<String, dynamic>) {
      final candidate =
          raw['id'] ?? raw['id_user'] ?? raw['id_chat'] ?? raw['id_message'];
      if (candidate is num) return candidate.toInt();
    }
    return -1;
  }

  static String? _trimOrNull(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }
}
