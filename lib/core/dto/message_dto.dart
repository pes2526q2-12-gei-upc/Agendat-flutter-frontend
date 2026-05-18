import 'package:agendat/core/dto/event_invitation_dto.dart';

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
    required this.readAt,
    required this.isRead,
    this.eventInvitation,
  });

  final int id;
  final int chatId;
  final int senderId;
  final String content;

  /// Valors coneguts: `text`, `image`, `file`, `event_invitation`.
  final String type;
  final String? fileUrl;
  final String sentAt;
  final bool edited;
  final String? readAt;
  final bool isRead;

  /// Quan [type] és `event_invitation`, el backend pot incloure la invitació
  /// completa per renderitzar la bombolla sense haver de fer una crida extra.
  final EventInvitationDto? eventInvitation;

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    final readAt = _trimOrNull(json['read_at']);
    final rawInvitation = json['event_invitation'];
    return MessageDto(
      id: ((json['id_message'] ?? json['id']) as num).toInt(),
      chatId: _parseNestedId(json['chat']),
      senderId: _parseNestedId(json['sender']),
      content: (json['content'] ?? '').toString().trim(),
      type: (json['type'] ?? 'text').toString().trim().toLowerCase(),
      fileUrl: _trimOrNull(json['file_url']),
      sentAt: (json['sent_at'] ?? '').toString().trim(),
      edited: json['edited'] == true,
      readAt: readAt,
      isRead: json['is_read'] == true || readAt != null,
      eventInvitation: rawInvitation is Map<String, dynamic>
          ? EventInvitationDto.fromJson(rawInvitation)
          : null,
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
