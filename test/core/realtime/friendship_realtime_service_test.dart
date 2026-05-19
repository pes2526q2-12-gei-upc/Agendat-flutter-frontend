import 'package:agendat/core/realtime/friendship_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FriendshipRealtimeService.socketUriForToken', () {
    test('uses ws for http base urls', () {
      final uri = FriendshipRealtimeService.socketUriForToken(
        'abc123',
        baseUrl: 'http://example.com/api/',
      );

      expect(uri.toString(), 'ws://example.com/ws/friends/?token=abc123');
    });

    test('uses wss for https base urls', () {
      final uri = FriendshipRealtimeService.socketUriForToken(
        'abc123',
        baseUrl: 'https://example.com/api/',
      );

      expect(uri.toString(), 'wss://example.com/ws/friends/?token=abc123');
    });
  });
}
