class ChatDto {
  const ChatDto({
    required this.id,
    required this.partnerJson,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.unreadCount,
    required this.canSend,
    required this.blockedByMe,
    required this.blockedMe,
  });

  final int id;
  final Map<String, dynamic> partnerJson;
  final String createdAt;
  final String updatedAt;
  final String lastMessage;
  final int unreadCount;
  final bool canSend;
  final bool blockedByMe;
  final bool blockedMe;

  factory ChatDto.fromJson(Map<String, dynamic> json) {
    final partner = _parsePartner(json);
    final lastMessage = _parseLastMessage(json);

    return ChatDto(
      id: ((json['id_chat'] ?? json['id']) as num).toInt(),
      partnerJson: partner,
      createdAt: _parseDateLike(json['created_at']),
      updatedAt: _parseDateLike(json['updated_at']),
      lastMessage: lastMessage,
      unreadCount: ((json['unread_count'] ?? 0) as num).toInt(),
      canSend: json['can_send'] != false,
      blockedByMe: json['blocked_by_me'] == true,
      blockedMe: json['blocked_me'] == true,
    );
  }

  static Map<String, dynamic> _parsePartner(Map<String, dynamic> json) {
    final explicit = json['partner'];
    if (explicit is Map<String, dynamic>) return explicit;

    final otherUser = json['other_user'];
    if (otherUser is Map<String, dynamic>) return otherUser;

    // Fallback for APIs that flatten the user in the chat payload.
    return <String, dynamic>{
      'id': json['partner_id'] ?? json['other_user_id'] ?? -1,
      'username': json['partner_username'] ?? json['other_user_username'] ?? '',
      'first_name': json['partner_first_name'] ?? json['other_user_first_name'],
      'last_name': json['partner_last_name'] ?? json['other_user_last_name'],
      'profile_image':
          json['partner_profile_image'] ?? json['other_user_profile_image'],
      'description':
          json['partner_description'] ?? json['other_user_description'],
    };
  }

  static String _parseLastMessage(Map<String, dynamic> json) {
    final candidate = json['last_message'];
    if (candidate is String) return candidate.trim();
    if (candidate is Map<String, dynamic>) {
      return (candidate['content'] ?? '').toString().trim();
    }
    return '';
  }

  static String _parseDateLike(dynamic value) {
    if (value == null)
      return DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
    final text = value.toString().trim();
    return text.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String()
        : text;
  }
}
