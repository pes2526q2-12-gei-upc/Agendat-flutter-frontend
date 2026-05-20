import 'package:agendat/core/services/chat_notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatNotificationPayload', () {
    test('separates actor avatar and chat attachment image', () {
      final payload = ChatNotificationPayload.fromData({
        'title': 'New message',
        'body': 'Photo incoming',
        'actor_profile_image': 'https://example.com/avatar.png',
        'chat_image_url': 'https://example.com/attachment.png',
        'actor_name': 'Aina',
        'chat_id': 42,
        'message_id': '99',
        'conversation_title': 'Aina',
      });

      expect(payload, isNotNull);
      expect(payload!.actorProfileImage, 'https://example.com/avatar.png');
      expect(payload.chatImageUrl, 'https://example.com/attachment.png');
      expect(payload.actorName, 'Aina');
      expect(payload.chatId, '42');
      expect(payload.messageId, '99');
      expect(payload.conversationTitle, 'Aina');
    });

    test('handles missing optional fields', () {
      final payload = ChatNotificationPayload.fromData({
        'title': 'New message',
        'body': 'Hello',
      });

      expect(payload, isNotNull);
      expect(payload!.title, 'New message');
      expect(payload.body, 'Hello');
      expect(payload.actorProfileImage, isNull);
      expect(payload.chatImageUrl, isNull);
      expect(payload.actorName, isNull);
    });

    test('accepts common sender avatar aliases', () {
      final senderAvatarPayload = ChatNotificationPayload.fromData({
        'title': 'New message',
        'body': 'Hello',
        'sender_avatar': 'https://example.com/sender.png',
      });
      final avatarUrlPayload = ChatNotificationPayload.fromData({
        'title': 'New message',
        'body': 'Hello',
        'avatar_url': 'https://example.com/avatar-url.png',
      });

      expect(
        senderAvatarPayload!.actorProfileImage,
        'https://example.com/sender.png',
      );
      expect(
        avatarUrlPayload!.actorProfileImage,
        'https://example.com/avatar-url.png',
      );
    });

    test('treats blank image URLs as absent', () {
      final payload = ChatNotificationPayload.fromData({
        'title': 'New message',
        'body': 'Hello',
        'actor_profile_image': '   ',
        'chat_image_url': '',
      });

      expect(payload, isNotNull);
      expect(payload!.actorProfileImage, isNull);
      expect(payload.chatImageUrl, isNull);
    });

    test('requires title and body', () {
      expect(
        ChatNotificationPayload.fromData({'title': 'New message'}),
        isNull,
      );
      expect(ChatNotificationPayload.fromData({'body': 'Hello'}), isNull);
    });
  });
}
