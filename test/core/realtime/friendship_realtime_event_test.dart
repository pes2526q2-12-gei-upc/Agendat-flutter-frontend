import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/realtime/friendship_realtime_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendshipRealtimeEvent.tryParse', () {
    test('parses friend_request.created', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friend_request.created',
        'request_id': 'req-created',
        'actor_id': 8,
        'friendship_id': 41,
        'friendship_status': 'request_received',
        'counterpart': {'id': 8, 'username': 'anna'},
        'friendship': {
          'id': 41,
          'status': 'pending',
          'counterpart': {'id': 8, 'username': 'anna'},
          'requested_by': {'id': 8, 'username': 'anna'},
          'created_at': '2026-05-19T09:00:00Z',
        },
      });

      expect(event, isA<FriendRequestCreatedEvent>());
      final created = event! as FriendRequestCreatedEvent;
      expect(created.actorId, 8);
      expect(created.friendshipId, 41);
      expect(created.friendshipStatus, FriendshipStatus.requestReceived);
      expect(created.counterpart.id, 8);
      expect(created.requestSnapshot?.id, 41);
    });

    test('parses friend_request.accepted with chat id', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friend_request.accepted',
        'request_id': 'req-accepted',
        'actor_id': 8,
        'friendship_id': 41,
        'friendship_status': 'friends',
        'chat_id': 77,
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendRequestAcceptedEvent>());
      final accepted = event! as FriendRequestAcceptedEvent;
      expect(accepted.chatId, 77);
      expect(accepted.friendshipStatus, FriendshipStatus.friends);
    });

    test('parses friend_request.rejected', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friend_request.rejected',
        'request_id': 'req-rejected',
        'actor_id': 8,
        'friendship_id': 41,
        'friendship_status': 'none',
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendRequestRejectedEvent>());
    });

    test('parses friend_request.cancelled', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friend_request.cancelled',
        'request_id': 'req-cancelled',
        'actor_id': 8,
        'friendship_id': 41,
        'friendship_status': 'none',
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendRequestCancelledEvent>());
    });

    test('parses friendship.blocked', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friendship.blocked',
        'request_id': 'req-blocked',
        'actor_id': 1,
        'friendship_id': 41,
        'friendship_status': 'blocked_by_me',
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendshipBlockedEvent>());
      final blocked = event! as FriendshipBlockedEvent;
      expect(blocked.friendshipStatus, FriendshipStatus.blockedByMe);
    });

    test('parses friendship.unblocked', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friendship.unblocked',
        'request_id': 'req-unblocked',
        'actor_id': 1,
        'friendship_id': 41,
        'friendship_status': 'none',
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendshipUnblockedEvent>());
    });

    test('parses friendship.unfriended', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friendship.unfriended',
        'request_id': 'req-unfriended',
        'actor_id': 8,
        'friendship_id': 41,
        'friendship_status': 'none',
        'counterpart': {'id': 8, 'username': 'anna'},
      });

      expect(event, isA<FriendshipUnfriendedEvent>());
    });

    test('parses error', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'error',
        'request_id': 'req-error',
        'code': 'invalid_state',
        'message': 'Not allowed',
      });

      expect(event, isA<FriendshipRealtimeErrorEvent>());
      final error = event! as FriendshipRealtimeErrorEvent;
      expect(error.code, 'invalid_state');
      expect(error.message, 'Not allowed');
    });

    test('rejects malformed payloads', () {
      final event = FriendshipRealtimeEvent.tryParse({
        'type': 'friend_request.created',
        'friendship_id': 41,
      });

      expect(event, isNull);
    });
  });
}
