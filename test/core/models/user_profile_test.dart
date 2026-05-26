import 'package:agendat/core/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('friendshipStatusFromString', () {
    test('parses blocked_by_me', () {
      expect(
        friendshipStatusFromString('blocked_by_me'),
        FriendshipStatus.blockedByMe,
      );
    });

    test('parses blocked_me', () {
      expect(
        friendshipStatusFromString('blocked_me'),
        FriendshipStatus.blockedMe,
      );
    });
  });
}
