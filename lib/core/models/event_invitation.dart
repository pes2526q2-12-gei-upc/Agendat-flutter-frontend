import 'package:agendat/features/social/data/models/user_summary.dart';

/// Estats possibles d'una invitació segons el backend.
enum EventInvitationStatus {
  pending,
  accepted,
  denied;

  String get apiValue {
    switch (this) {
      case EventInvitationStatus.pending:
        return 'pending';
      case EventInvitationStatus.accepted:
        return 'accepted';
      case EventInvitationStatus.denied:
        return 'denied';
    }
  }

  static EventInvitationStatus fromApi(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'accepted':
        return EventInvitationStatus.accepted;
      case 'denied':
      case 'rejected':
        return EventInvitationStatus.denied;
      case 'pending':
      default:
        return EventInvitationStatus.pending;
    }
  }
}

/// Model de domini d'una invitació a una sessió d'esdeveniment.
class EventInvitation {
  const EventInvitation({
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
  final DateTime? sessionStartTime;
  final DateTime? sessionEndTime;
  final String eventCode;
  final String eventDenomination;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;
  final UserSummary? sender;
  final UserSummary? recipient;
  final EventInvitationStatus status;
  final int? messageId;
  final int? chatId;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == EventInvitationStatus.pending;
  bool get isAccepted => status == EventInvitationStatus.accepted;
  bool get isDenied => status == EventInvitationStatus.denied;

  EventInvitation copyWith({
    int? id,
    int? sessionId,
    DateTime? sessionStartTime,
    DateTime? sessionEndTime,
    String? eventCode,
    String? eventDenomination,
    DateTime? eventStartDate,
    DateTime? eventEndDate,
    UserSummary? sender,
    UserSummary? recipient,
    EventInvitationStatus? status,
    int? messageId,
    int? chatId,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return EventInvitation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      sessionEndTime: sessionEndTime ?? this.sessionEndTime,
      eventCode: eventCode ?? this.eventCode,
      eventDenomination: eventDenomination ?? this.eventDenomination,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      eventEndDate: eventEndDate ?? this.eventEndDate,
      sender: sender ?? this.sender,
      recipient: recipient ?? this.recipient,
      status: status ?? this.status,
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
