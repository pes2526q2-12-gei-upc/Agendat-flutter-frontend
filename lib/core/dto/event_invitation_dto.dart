/// Representació plana (DTO) d'una invitació a una sessió d'esdeveniment,
/// tal com la retornen els endpoints `/api/sessions/{id}/invitations/` i
/// `/api/invitations/{id}/accept|reject/`.
class EventInvitationDto {
  const EventInvitationDto({
    required this.id,
    required this.sessionId,
    required this.sessionStartTime,
    required this.sessionEndTime,
    required this.eventCode,
    required this.eventDenomination,
    required this.eventStartDate,
    required this.eventEndDate,
    required this.sender,
    required this.recipient,
    required this.status,
    required this.messageId,
    required this.chatId,
    required this.createdAt,
    required this.respondedAt,
  });

  final int id;
  final int sessionId;
  final String? sessionStartTime;
  final String? sessionEndTime;
  final String eventCode;
  final String eventDenomination;
  final String? eventStartDate;
  final String? eventEndDate;
  final Map<String, dynamic>? sender;
  final Map<String, dynamic>? recipient;
  final String status;
  final int? messageId;
  final int? chatId;
  final String? createdAt;
  final String? respondedAt;

  factory EventInvitationDto.fromJson(Map<String, dynamic> json) {
    return EventInvitationDto(
      id: (json['id'] as num).toInt(),
      sessionId:
          ((json['session_id'] ?? json['session']) as num?)?.toInt() ?? 0,
      sessionStartTime: _trimOrNull(json['session_start_time']),
      sessionEndTime: _trimOrNull(json['session_end_time']),
      eventCode: (json['event_code'] ?? '').toString().trim(),
      eventDenomination: (json['event_denomination'] ?? '').toString().trim(),
      eventStartDate: _trimOrNull(json['event_start_date']),
      eventEndDate: _trimOrNull(json['event_end_date']),
      sender: _asMap(json['sender']),
      recipient: _asMap(json['recipient']),
      status: (json['status'] ?? 'pending').toString().trim().toLowerCase(),
      messageId: (json['message_id'] as num?)?.toInt(),
      chatId: (json['chat_id'] as num?)?.toInt(),
      createdAt: _trimOrNull(json['created_at']),
      respondedAt: _trimOrNull(json['responded_at']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    return null;
  }

  static String? _trimOrNull(dynamic raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }
}
