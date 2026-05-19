import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/core/realtime/friendship_realtime_event.dart';
import 'package:agendat/core/state/auth_session.dart';
import 'package:agendat/core/state/pending_friend_requests_notifier.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final query = ProfileQuery.instance;

  setUp(() {
    currentLoggedInUser = {'id': 1, 'username': 'me'};
    currentAuthToken = 'token';
    QueryClient.instance.invalidateAll();
    pendingFriendRequestsNotifier.value = 0;
    _resetLocalFriendshipState(query);
  });

  tearDown(() {
    QueryClient.instance.invalidateAll();
    pendingFriendRequestsNotifier.value = 0;
    _resetLocalFriendshipState(query);
    currentLoggedInUser = null;
    currentAuthToken = null;
  });

  group('ProfileQuery.applyFriendshipRealtimeEvent', () {
    test(
      'created events populate sent vs received correctly and update badge',
      () async {
        final sentUser = _user(7, 'anna');
        final receivedUser = _user(8, 'bert');

        await query.applyFriendshipRealtimeEvent(
          FriendRequestCreatedEvent(
            requestId: 'req-sent',
            actorId: 1,
            friendshipId: 70,
            friendshipStatus: FriendshipStatus.requestSent,
            counterpart: sentUser,
            requestSnapshot: _pendingRequest(70, sentUser),
          ),
        );

        await query.applyFriendshipRealtimeEvent(
          FriendRequestCreatedEvent(
            requestId: 'req-received',
            actorId: 8,
            friendshipId: 71,
            friendshipStatus: FriendshipStatus.requestReceived,
            counterpart: receivedUser,
            requestSnapshot: _pendingRequest(71, receivedUser),
          ),
        );

        final requests = QueryClient.instance.getQueryData<FriendRequestsData>(
          'profile:friend-requests:1',
        );

        expect(requests, isNotNull);
        expect(requests!.sent.map((r) => r.id), [70]);
        expect(requests.received.map((r) => r.id), [71]);
        expect(pendingFriendRequestsNotifier.value, 1);
      },
    );

    test(
      'accepted events remove pending requests, add friends, clear local state, and invalidate chats when chat hydration cannot run',
      () async {
        final friend = _user(7, 'anna');

        QueryClient.instance.setQueryData<FriendRequestsData>(
          'profile:friend-requests:1',
          FriendRequestsData(
            sent: [_pendingRequest(80, friend)],
            received: [_pendingRequest(80, friend)],
          ),
        );
        QueryClient.instance.setQueryData<List<UserSummary>>(
          'profile:friends:1',
          const [],
        );
        QueryClient.instance.setQueryData<ProfileResult>(
          'profile:user:7',
          ProfileSuccess(profile: _profile(friend.id, FriendshipStatus.none)),
        );
        QueryClient.instance.setQueryData<List<Chat>>('chats:list', [
          _chat(friend),
        ]);
        query.markUserBlocked(friend.id);
        query.markUserUnfriended(friend.id);

        await query.applyFriendshipRealtimeEvent(
          FriendRequestAcceptedEvent(
            requestId: 'req-accepted',
            actorId: 7,
            friendshipId: 80,
            friendshipStatus: FriendshipStatus.friends,
            counterpart: friend,
            chatId: null,
          ),
        );

        final requests = QueryClient.instance.getQueryData<FriendRequestsData>(
          'profile:friend-requests:1',
        );
        final friends = QueryClient.instance.getQueryData<List<UserSummary>>(
          'profile:friends:1',
        );
        final profile = QueryClient.instance.getQueryData<ProfileResult>(
          'profile:user:7',
        );

        expect(requests, isNotNull);
        expect(requests!.sent, isEmpty);
        expect(requests.received, isEmpty);
        expect(friends?.map((user) => user.id), [7]);
        expect(query.locallyBlockedUserIds.contains(7), isFalse);
        expect(query.locallyUnfriendedUserIds.contains(7), isFalse);
        expect(
          (profile! as ProfileSuccess).profile.friendshipStatus,
          FriendshipStatus.friends,
        );
        expect(
          QueryClient.instance.getQueryData<List<Chat>>('chats:list'),
          isNull,
        );
        expect(pendingFriendRequestsNotifier.value, 0);
      },
    );

    test(
      'blockedByMe updates blocked users cache and removes the chat from the list',
      () async {
        final friend = _user(7, 'anna');

        QueryClient.instance.setQueryData<List<UserSummary>>(
          'profile:friends:1',
          [friend],
        );
        QueryClient.instance.setQueryData<List<UserSummary>>(
          'profile:blocked:1',
          const [],
        );
        QueryClient.instance.setQueryData<List<Chat>>('chats:list', [
          _chat(friend),
        ]);
        QueryClient.instance.setQueryData<Chat>(
          'chats:detail:70',
          _chat(friend),
        );

        await query.applyFriendshipRealtimeEvent(
          FriendshipBlockedEvent(
            requestId: 'req-blocked',
            actorId: 1,
            friendshipId: 90,
            friendshipStatus: FriendshipStatus.blockedByMe,
            counterpart: friend,
          ),
        );

        final blocked = QueryClient.instance.getQueryData<List<UserSummary>>(
          'profile:blocked:1',
        );
        final friends = QueryClient.instance.getQueryData<List<UserSummary>>(
          'profile:friends:1',
        );
        final chatList = QueryClient.instance.getQueryData<List<Chat>>(
          'chats:list',
        );
        final chatDetail = QueryClient.instance.getQueryData<Chat>(
          'chats:detail:70',
        );

        expect(blocked?.map((user) => user.id), [7]);
        expect(friends, isEmpty);
        expect(chatList, isEmpty);
        expect(chatDetail, isNotNull);
        expect(chatDetail!.blockedByMe, isTrue);
        expect(chatDetail.canSend, isFalse);
      },
    );

    test(
      'blockedMe leaves blocked users cache untouched and keeps chats visible but non-sendable',
      () async {
        final friend = _user(7, 'anna');
        final someoneElse = _user(9, 'carla');

        QueryClient.instance.setQueryData<List<UserSummary>>(
          'profile:friends:1',
          [friend],
        );
        QueryClient.instance.setQueryData<List<UserSummary>>(
          'profile:blocked:1',
          [someoneElse],
        );
        QueryClient.instance.setQueryData<List<Chat>>('chats:list', [
          _chat(friend),
        ]);
        QueryClient.instance.setQueryData<Chat>(
          'chats:detail:70',
          _chat(friend),
        );

        await query.applyFriendshipRealtimeEvent(
          FriendshipBlockedEvent(
            requestId: 'req-blocked-me',
            actorId: 7,
            friendshipId: 91,
            friendshipStatus: FriendshipStatus.blockedMe,
            counterpart: friend,
          ),
        );

        final blocked = QueryClient.instance.getQueryData<List<UserSummary>>(
          'profile:blocked:1',
        );
        final friends = QueryClient.instance.getQueryData<List<UserSummary>>(
          'profile:friends:1',
        );
        final chatList = QueryClient.instance.getQueryData<List<Chat>>(
          'chats:list',
        );
        final chatDetail = QueryClient.instance.getQueryData<Chat>(
          'chats:detail:70',
        );

        expect(blocked?.map((user) => user.id), [9]);
        expect(friends, isEmpty);
        expect(chatList, isNotEmpty);
        expect(chatList!.single.blockedMe, isTrue);
        expect(chatList.single.blockedByMe, isFalse);
        expect(chatList.single.canSend, isFalse);
        expect(chatDetail!.blockedMe, isTrue);
        expect(chatDetail.canSend, isFalse);
      },
    );

    test(
      'duplicate application of the same event does not duplicate rows or drift badges',
      () async {
        final friend = _user(7, 'anna');
        final event = FriendRequestCreatedEvent(
          requestId: 'req-duplicate',
          actorId: 7,
          friendshipId: 92,
          friendshipStatus: FriendshipStatus.requestReceived,
          counterpart: friend,
          requestSnapshot: _pendingRequest(92, friend),
        );

        await query.applyFriendshipRealtimeEvent(event);
        await query.applyFriendshipRealtimeEvent(event);

        final requests = QueryClient.instance.getQueryData<FriendRequestsData>(
          'profile:friend-requests:1',
        );

        expect(requests, isNotNull);
        expect(requests!.received.map((request) => request.id), [92]);
        expect(pendingFriendRequestsNotifier.value, 1);
      },
    );
  });
}

void _resetLocalFriendshipState(ProfileQuery query) {
  for (final id in query.locallyBlockedUserIds.toList()) {
    query.markUserUnblocked(id);
  }
  for (final id in query.locallyUnfriendedUserIds.toList()) {
    query.markUserRefriended(id);
  }
}

UserSummary _user(int id, String username) {
  return UserSummary(id: id, username: username);
}

PendingFriendRequest _pendingRequest(int id, UserSummary counterpart) {
  return PendingFriendRequest(
    id: id,
    status: 'pending',
    counterpart: counterpart,
    requestedBy: counterpart,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
  );
}

UserProfile _profile(int userId, FriendshipStatus status) {
  return UserProfile(
    id: userId,
    username: 'user-$userId',
    friendshipStatus: status,
  );
}

Chat _chat(UserSummary partner) {
  return Chat(
    id: 70,
    partner: partner,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T09:00:00Z'),
    lastMessage: 'Hola',
    lastMessageTime: DateTime.parse('2026-05-19T09:00:00Z'),
    unreadCount: 0,
    canSend: true,
    blockedByMe: false,
    blockedMe: false,
  );
}
