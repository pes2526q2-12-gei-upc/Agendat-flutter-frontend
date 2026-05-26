import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatsQuery.applyRealtimeEvent', () {
    setUp(() {
      QueryClient.instance.invalidateAll();
    });

    tearDown(() {
      QueryClient.instance.invalidateAll();
    });

    test('marks matching cached messages as read', () {
      final chat = Chat(
        id: 42,
        partner: const UserSummary(id: 5, username: 'partner'),
        createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
        updatedAt: DateTime.parse('2026-05-14T10:06:00Z'),
        lastMessage: 'Hola',
        lastMessageTime: DateTime.parse('2026-05-14T10:06:00Z'),
        unreadCount: 0,
        canSend: true,
        blockedByMe: false,
        blockedMe: false,
      );
      final cachedMessages = [
        ChatMessage(
          id: 1,
          chatId: 42,
          senderId: 7,
          content: 'Primer',
          type: 'text',
          sentAt: DateTime.parse('2026-05-14T10:00:00Z'),
          edited: false,
          readAt: null,
          isRead: false,
        ),
        ChatMessage(
          id: 2,
          chatId: 42,
          senderId: 5,
          content: 'Segon',
          type: 'text',
          sentAt: DateTime.parse('2026-05-14T10:01:00Z'),
          edited: false,
          readAt: null,
          isRead: false,
        ),
      ];

      QueryClient.instance.setQueryData('chats:messages:42', cachedMessages);

      ChatsQuery.instance.applyRealtimeEvent(
        ChatMessagesReadEvent(
          requestId: 'req-1',
          chatId: 42,
          chat: chat,
          messageIds: const [1],
          readAt: DateTime.parse('2026-05-14T10:05:00Z'),
        ),
      );

      final updated = QueryClient.instance.getQueryData<List<ChatMessage>>(
        'chats:messages:42',
      );

      expect(updated, isNotNull);
      expect(updated![0].isRead, isTrue);
      expect(updated[0].readAt, DateTime.parse('2026-05-14T10:05:00Z'));
      expect(updated[1].isRead, isFalse);
      expect(updated[1].readAt, isNull);
    });

    test(
      'syncs blockedMe friendship state into cached chat list and detail',
      () {
        final chat = Chat(
          id: 42,
          partner: const UserSummary(id: 5, username: 'partner'),
          createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
          updatedAt: DateTime.parse('2026-05-14T10:06:00Z'),
          lastMessage: 'Hola',
          lastMessageTime: DateTime.parse('2026-05-14T10:06:00Z'),
          unreadCount: 0,
          canSend: true,
          blockedByMe: false,
          blockedMe: false,
        );

        QueryClient.instance.setQueryData<List<Chat>>('chats:list', [chat]);
        QueryClient.instance.setQueryData<Chat>('chats:detail:42', chat);

        ChatsQuery.instance.syncPartnerFriendshipStateInCache(
          5,
          status: FriendshipStatus.blockedMe,
        );

        final list = QueryClient.instance.getQueryData<List<Chat>>(
          'chats:list',
        );
        final detail = QueryClient.instance.getQueryData<Chat>(
          'chats:detail:42',
        );

        expect(list, isNotNull);
        expect(list!.single.canSend, isFalse);
        expect(list.single.blockedMe, isTrue);
        expect(list.single.blockedByMe, isFalse);
        expect(detail, isNotNull);
        expect(detail!.canSend, isFalse);
        expect(detail.blockedMe, isTrue);
      },
    );

    test(
      'removes blockedByMe chats from the list but preserves read-only detail',
      () {
        final chat = Chat(
          id: 42,
          partner: const UserSummary(id: 5, username: 'partner'),
          createdAt: DateTime.parse('2026-05-14T09:00:00Z'),
          updatedAt: DateTime.parse('2026-05-14T10:06:00Z'),
          lastMessage: 'Hola',
          lastMessageTime: DateTime.parse('2026-05-14T10:06:00Z'),
          unreadCount: 0,
          canSend: true,
          blockedByMe: false,
          blockedMe: false,
        );

        QueryClient.instance.setQueryData<List<Chat>>('chats:list', [chat]);
        QueryClient.instance.setQueryData<Chat>('chats:detail:42', chat);

        ChatsQuery.instance.syncPartnerFriendshipStateInCache(
          5,
          status: FriendshipStatus.blockedByMe,
        );

        final list = QueryClient.instance.getQueryData<List<Chat>>(
          'chats:list',
        );
        final detail = QueryClient.instance.getQueryData<Chat>(
          'chats:detail:42',
        );

        expect(list, isEmpty);
        expect(detail, isNotNull);
        expect(detail!.canSend, isFalse);
        expect(detail.blockedByMe, isTrue);
      },
    );
  });
}
