import 'package:agendat/core/dto/chat_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatDto', () {
    test('uses a readable last-message fallback for image messages', () {
      final dto = ChatDto.fromJson({
        'id_chat': 2,
        'partner': {'id': 7, 'username': 'aina'},
        'created_at': '2026-05-21T09:00:00Z',
        'updated_at': '2026-05-21T09:01:00Z',
        'last_message': {
          'content': '',
          'type': 'image',
          'file_url': 'https://example.com/photo.jpg',
        },
      });

      expect(dto.lastMessage, 'Photo');
    });
  });
}
