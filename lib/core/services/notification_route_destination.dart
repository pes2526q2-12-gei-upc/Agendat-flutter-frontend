import 'package:agendat/core/services/notification_payload.dart';

enum NotificationDestinationType {
  chatDetail,
  friendRequests,
  userProfile,
  eventInvitationDetail,
  eventReviewDetail,
  eventSessionDetail,
}

class NotificationDestination {
  const NotificationDestination({
    required this.type,
    this.chatId,
    this.userId,
    this.eventCode,
  });

  final NotificationDestinationType type;
  final int? chatId;
  final int? userId;
  final String? eventCode;
}

NotificationDestination? notificationDestinationFromPayload(
  NotificationPayload notification,
) {
  final route = notification.target?.route;
  if (route == null) return null;
  final params = route.params;

  switch (route.name) {
    case 'chat_detail':
      final chatId = _intParam(params, 'chat_id');
      if (chatId == null) return null;
      return NotificationDestination(
        type: NotificationDestinationType.chatDetail,
        chatId: chatId,
      );
    case 'friend_requests':
      return const NotificationDestination(
        type: NotificationDestinationType.friendRequests,
      );
    case 'user_profile':
      final userId = _intParam(params, 'user_id');
      if (userId == null) return null;
      return NotificationDestination(
        type: NotificationDestinationType.userProfile,
        userId: userId,
      );
    case 'event_invitation_detail':
      return _eventDestination(
        notification,
        NotificationDestinationType.eventInvitationDetail,
      );
    case 'event_review_detail':
      return _eventDestination(
        notification,
        NotificationDestinationType.eventReviewDetail,
      );
    case 'event_session_detail':
      return _eventDestination(
        notification,
        NotificationDestinationType.eventSessionDetail,
      );
    default:
      return null;
  }
}

NotificationDestination? _eventDestination(
  NotificationPayload notification,
  NotificationDestinationType type,
) {
  final params = notification.target?.route?.params ?? const <String, dynamic>{};
  final eventCode = _stringParam(params, 'event_code') ?? notification.target?.id;
  if (eventCode == null || eventCode.isEmpty) return null;
  return NotificationDestination(type: type, eventCode: eventCode);
}

int? _intParam(Map<String, dynamic> params, String key) {
  final value = params[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

String? _stringParam(Map<String, dynamic> params, String key) {
  final value = params[key]?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
