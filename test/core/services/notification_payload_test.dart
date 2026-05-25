import 'dart:convert';

import 'package:agendat/core/services/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('parses structured JSON-string fields', () {
      final payload = NotificationPayload.fromData({
        'id': 'abc',
        'notification_type': 'chat_message',
        'title': 'Fallback title',
        'body': 'Fallback body',
        'actor': jsonEncode({
          'id': 7,
          'username': 'maria',
          'display_name': 'Maria',
          'profile_image': '/media/maria.jpg',
        }),
        'action': jsonEncode({
          'key': 'chat.message',
          'label': 'sent you a message',
        }),
        'target': jsonEncode({
          'type': 'chat',
          'id': 42,
          'name': 'Xat amb Maria',
          'route': {
            'name': 'chat_detail',
            'params': {'chat_id': 42, 'message_id': 99},
          },
        }),
        'preview': jsonEncode({'kind': 'text', 'text': 'Hola'}),
        'read_at': '2026-05-20T09:00:00Z',
        'created_at': '2026-05-20T08:59:00Z',
      });

      expect(payload, isNotNull);
      expect(payload!.id, 'abc');
      expect(payload.notificationType, 'chat_message');
      expect(payload.actor!.displayName, 'Maria');
      expect(payload.actor!.profileImage, '/media/maria.jpg');
      expect(payload.action!.key, 'chat.message');
      expect(payload.target!.route!.name, 'chat_detail');
      expect(payload.target!.route!.params['chat_id'], 42);
      expect(payload.preview!.text, 'Hola');
      expect(payload.readAt, DateTime.parse('2026-05-20T09:00:00Z'));
      expect(payload.createdAt, DateTime.parse('2026-05-20T08:59:00Z'));
    });

    test('parses every structured action key used by push notifications', () {
      const keys = [
        'friend_request.sent',
        'friend_request.accepted',
        'chat.message',
        'event_invitation.sent',
        'event_invitation.accepted',
        'review.liked',
        'event.reminder',
      ];

      for (final key in keys) {
        final payload = NotificationPayload.fromData({
          'action': jsonEncode({'key': key}),
        });

        expect(payload, isNotNull, reason: key);
        expect(payload!.action!.key, key);
      }
    });

    test('keeps legacy flat chat push fields working', () {
      final payload = NotificationPayload.fromData({
        'title': 'New message',
        'body': 'Hello',
        'actor_name': 'Aina',
        'actor_profile_image': 'https://example.com/avatar.png',
        'chat_id': 42,
        'message_id': '99',
        'conversation_title': 'Aina',
      });

      expect(payload, isNotNull);
      expect(payload!.action!.key, 'chat.message');
      expect(payload.actor!.displayName, 'Aina');
      expect(payload.actor!.profileImage, 'https://example.com/avatar.png');
      expect(payload.target!.route!.name, 'chat_detail');
      expect(payload.target!.route!.params['chat_id'], '42');
      expect(payload.target!.route!.params['message_id'], '99');
      expect(payload.preview!.text, 'Hello');
    });

    test('uses file_url as image preview for image chat pushes', () {
      final payload = NotificationPayload.fromData({
        'title': 'New message',
        'body': '',
        'type': 'image',
        'file_url': 'https://example.com/photo.jpg',
        'chat_id': 42,
      });

      expect(payload, isNotNull);
      expect(payload!.preview!.kind, 'image');
      expect(payload.preview!.imageUrl, 'https://example.com/photo.jpg');
    });

    test('accepts file_url inside structured preview', () {
      final payload = NotificationPayload.fromData({
        'action': jsonEncode({'key': 'chat.message'}),
        'preview': jsonEncode({
          'type': 'image',
          'file_url': 'https://example.com/photo.jpg',
        }),
      });

      expect(payload, isNotNull);
      expect(payload!.preview!.kind, 'image');
      expect(payload.preview!.imageUrl, 'https://example.com/photo.jpg');
    });

    test(
      'returns null when neither structured nor fallback display exists',
      () {
        expect(NotificationPayload.fromData({'ignored': 'value'}), isNull);
      },
    );
  });
}
