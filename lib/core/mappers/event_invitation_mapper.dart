import 'package:agendat/core/dto/event_invitation_dto.dart';
import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

extension EventInvitationDtoMapper on EventInvitationDto {
  EventInvitation toDomain() {
    return EventInvitation(
      id: id,
      sessionId: sessionId,
      sessionStartTime: _parseOptionalDateTime(sessionStartTime),
      sessionEndTime: _parseOptionalDateTime(sessionEndTime),
      eventCode: eventCode,
      eventDenomination: eventDenomination,
      eventStartDate: _parseOptionalDateTime(eventStartDate),
      eventEndDate: _parseOptionalDateTime(eventEndDate),
      sender: sender == null ? null : UserSummary.fromJson(sender!),
      recipient: recipient == null ? null : UserSummary.fromJson(recipient!),
      status: EventInvitationStatus.fromApi(status),
      messageId: messageId,
      chatId: chatId,
      createdAt: _parseOptionalDateTime(createdAt),
      respondedAt: _parseOptionalDateTime(respondedAt),
    );
  }
}

DateTime? _parseOptionalDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
