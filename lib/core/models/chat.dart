import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Conversa individual (partner 1‑a‑1) amb resum del darrer missatge i comptadors.
class Chat {
  const Chat({
    required this.id,
    required this.partner,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  /// Identificador del xat assignat pel backend.
  final int id;

  /// L’altre participant de la conversa.
  final UserSummary partner;

  /// Text de l’últim missatge (per llista de xats).
  final String lastMessage;

  /// Marca de temps de l’últim missatge.
  final DateTime lastMessageTime;

  /// Missatges encara no llegits per l’usuari actual.
  final int unreadCount;

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: (json['id'] as num).toInt(),
      partner: UserSummary.fromJson(json['partner'] as Map<String, dynamic>),
      lastMessage: (json['last_message'] as String?)?.trim() ?? '',
      lastMessageTime: parseFlexibleDateTime(json['last_message_time']),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner': {
        'id': partner.id,
        'username': partner.username,
        'first_name': partner.firstName,
        'last_name': partner.lastName,
        'profile_image': partner.profileImage,
        'description': partner.description,
      },
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  Chat copyWith({
    int? id,
    UserSummary? partner,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return Chat(
      id: id ?? this.id,
      partner: partner ?? this.partner,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          partner.id == other.partner.id &&
          lastMessage == other.lastMessage &&
          lastMessageTime == other.lastMessageTime &&
          unreadCount == other.unreadCount;

  @override
  int get hashCode =>
      Object.hash(id, partner.id, lastMessage, lastMessageTime, unreadCount);
}
