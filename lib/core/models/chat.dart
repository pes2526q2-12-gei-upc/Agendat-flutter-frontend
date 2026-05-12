import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Conversa individual (partner 1‑a‑1) amb resum del darrer missatge i comptadors.
class Chat {
  const Chat({
    required this.id,
    required this.partner,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.canSend,
    required this.blockedByMe,
    required this.blockedMe,
  });

  /// Identificador del xat assignat pel backend.
  final int id;

  /// L’altre participant de la conversa.
  final UserSummary partner;

  /// Data de creació del xat.
  final DateTime createdAt;

  /// Darrera actualització del xat.
  final DateTime updatedAt;

  /// Text de l’últim missatge (per llista de xats).
  final String lastMessage;

  /// Marca de temps de l’últim missatge.
  final DateTime lastMessageTime;

  /// Missatges encara no llegits per l’usuari actual.
  final int unreadCount;

  /// Estat derivat de backend: permet enviar missatges.
  final bool canSend;

  /// L’usuari actual ha bloquejat l’altre usuari.
  final bool blockedByMe;

  /// L’altre usuari ha bloquejat l’usuari actual.
  final bool blockedMe;

  /// Una línia curta que explica per què no es poden enviar missatges (p. ex. llista de xats).
  String get inactiveMessagingReasonShort {
    if (blockedByMe) return 'Has bloquejat aquest usuari';
    if (blockedMe) return 'Aquest usuari t\'ha bloquejat';
    return 'Ja no sou amics amb aquest usuari';
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: (json['id'] as num).toInt(),
      partner: UserSummary.fromJson(json['partner'] as Map<String, dynamic>),
      createdAt: parseFlexibleDateTime(json['created_at']),
      updatedAt: parseFlexibleDateTime(json['updated_at']),
      lastMessage: (json['last_message'] as String?)?.trim() ?? '',
      lastMessageTime: parseFlexibleDateTime(
        json['updated_at'] ?? json['last_message_time'],
      ),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      canSend:
          json['can_send'] != false &&
          json['blocked_me'] != true &&
          json['blocked_by_me'] != true,
      blockedByMe: json['blocked_by_me'] == true,
      blockedMe: json['blocked_me'] == true,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'can_send': canSend,
      'blocked_by_me': blockedByMe,
      'blocked_me': blockedMe,
    };
  }

  Chat copyWith({
    int? id,
    UserSummary? partner,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? canSend,
    bool? blockedByMe,
    bool? blockedMe,
  }) {
    return Chat(
      id: id ?? this.id,
      partner: partner ?? this.partner,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      canSend: canSend ?? this.canSend,
      blockedByMe: blockedByMe ?? this.blockedByMe,
      blockedMe: blockedMe ?? this.blockedMe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chat &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          partner.id == other.partner.id &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          lastMessage == other.lastMessage &&
          lastMessageTime == other.lastMessageTime &&
          unreadCount == other.unreadCount &&
          canSend == other.canSend &&
          blockedByMe == other.blockedByMe &&
          blockedMe == other.blockedMe;

  @override
  int get hashCode => Object.hash(
    id,
    partner.id,
    createdAt,
    updatedAt,
    lastMessage,
    lastMessageTime,
    unreadCount,
    canSend,
    blockedByMe,
    blockedMe,
  );
}
