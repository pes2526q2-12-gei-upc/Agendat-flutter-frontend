import 'package:agendat/core/dto/message_dto.dart';
import 'package:agendat/core/mappers/chat_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageDto read receipts', () {
    test('maps read_at to a read domain message', () {
      final message = MessageDto.fromJson({
        'id_message': 10,
        'chat': {'id_chat': 3},
        'sender': {'id_user': 7},
        'content': 'Hola',
        'type': 'text',
        'sent_at': '2026-05-14T10:00:00Z',
        'edited': false,
        'read_at': '2026-05-14T10:05:00Z',
      }).toDomain();

      expect(message.isRead, isTrue);
      expect(message.readAt, DateTime.parse('2026-05-14T10:05:00Z'));
    });

    test('maps is_read true without read_at as read', () {
      final message = MessageDto.fromJson({
        'id_message': 11,
        'chat': {'id_chat': 3},
        'sender': {'id_user': 7},
        'content': 'Hola',
        'type': 'text',
        'sent_at': '2026-05-14T10:00:00Z',
        'edited': false,
        'is_read': true,
      }).toDomain();

      expect(message.isRead, isTrue);
      expect(message.readAt, isNull);
    });

    test('defaults missing receipt fields to unread', () {
      final message = MessageDto.fromJson({
        'id_message': 12,
        'chat': {'id_chat': 3},
        'sender': {'id_user': 7},
        'content': 'Hola',
        'type': 'text',
        'sent_at': '2026-05-14T10:00:00Z',
        'edited': false,
      }).toDomain();

      expect(message.isRead, isFalse);
      expect(message.readAt, isNull);
    });
  });
}
