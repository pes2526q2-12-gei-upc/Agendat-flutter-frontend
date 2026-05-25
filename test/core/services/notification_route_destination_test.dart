import 'package:agendat/core/services/notification_payload.dart';
import 'package:agendat/core/services/notification_route_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notificationDestinationFromPayload', () {
    test('maps chat_detail when chat_id is present', () {
      final destination = notificationDestinationFromPayload(
        _notificationWithRoute('chat_detail', {'chat_id': '42'}),
      );

      expect(destination!.type, NotificationDestinationType.chatDetail);
      expect(destination.chatId, 42);
    });

    test('maps friend_requests without required params', () {
      final destination = notificationDestinationFromPayload(
        _notificationWithRoute('friend_requests', const {}),
      );

      expect(destination!.type, NotificationDestinationType.friendRequests);
    });

    test('maps user_profile when user_id is present', () {
      final destination = notificationDestinationFromPayload(
        _notificationWithRoute('user_profile', {'user_id': 7}),
      );

      expect(destination!.type, NotificationDestinationType.userProfile);
      expect(destination.userId, 7);
    });

    test('maps event routes to an event code destination', () {
      for (final entry in const {
        'event_invitation_detail':
            NotificationDestinationType.eventInvitationDetail,
        'event_review_detail': NotificationDestinationType.eventReviewDetail,
        'event_session_detail': NotificationDestinationType.eventSessionDetail,
      }.entries) {
        final destination = notificationDestinationFromPayload(
          _notificationWithRoute(entry.key, {'event_code': 'EVT-1'}),
        );

        expect(destination!.type, entry.value);
        expect(destination.eventCode, 'EVT-1');
      }
    });

    test('uses target id as event code fallback', () {
      const notification = NotificationPayload(
        target: NotificationTarget(
          id: 'EVT-2',
          route: NotificationRoute(name: 'event_session_detail', params: {}),
        ),
      );

      final destination = notificationDestinationFromPayload(notification);

      expect(destination!.eventCode, 'EVT-2');
    });

    test('returns null for unsupported or incomplete routes', () {
      expect(
        notificationDestinationFromPayload(
          _notificationWithRoute('chat_detail', const {}),
        ),
        isNull,
      );
      expect(
        notificationDestinationFromPayload(
          _notificationWithRoute('user_profile', const {}),
        ),
        isNull,
      );
      expect(
        notificationDestinationFromPayload(
          _notificationWithRoute('unknown', const {}),
        ),
        isNull,
      );
    });
  });
}

NotificationPayload _notificationWithRoute(
  String name,
  Map<String, dynamic> params,
) {
  return NotificationPayload(
    target: NotificationTarget(
      route: NotificationRoute(name: name, params: params),
    ),
  );
}
