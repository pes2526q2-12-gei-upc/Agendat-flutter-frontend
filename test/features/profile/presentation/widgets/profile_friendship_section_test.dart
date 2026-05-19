import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_friendship_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('blockedByMe shows the unblock action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileFriendshipSection(
            currentUserId: 1,
            viewedUserId: 2,
            status: FriendshipStatus.blockedByMe,
            isFriendshipBusy: false,
            isBlockBusy: false,
            onSendFriendRequest: () {},
            onCancelFriendRequest: () {},
            onAcceptFriendRequest: () {},
            onRejectFriendRequest: () {},
            onUnfriend: () {},
            onUnblock: () {},
          ),
        ),
      ),
    );

    expect(find.text('Desbloquejar'), findsOneWidget);
  });

  testWidgets('blockedMe shows a disabled notice with no friendship actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileFriendshipSection(
            currentUserId: 1,
            viewedUserId: 2,
            status: FriendshipStatus.blockedMe,
            isFriendshipBusy: false,
            isBlockBusy: false,
            onSendFriendRequest: () {},
            onCancelFriendRequest: () {},
            onAcceptFriendRequest: () {},
            onRejectFriendRequest: () {},
            onUnfriend: () {},
            onUnblock: () {},
          ),
        ),
      ),
    );

    expect(find.text('Aquest usuari t\'ha bloquejat'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
