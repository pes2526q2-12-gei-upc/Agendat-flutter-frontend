import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    unreadChatConversationsNotifier.value = 0;
  });

  test('syncUnreadChatConversationsBadge sums unread messages', () {
    syncUnreadChatConversationsBadge([
      _chat(id: 1, unreadCount: 2),
      _chat(id: 2, unreadCount: 0),
      _chat(id: 3, unreadCount: 4),
    ]);

    expect(unreadChatConversationsNotifier.value, 6);
  });

  test('syncUnreadChatConversationsBadge ignores negative unread counts', () {
    syncUnreadChatConversationsBadge([
      _chat(id: 1, unreadCount: -1),
      _chat(id: 2, unreadCount: 3),
    ]);

    expect(unreadChatConversationsNotifier.value, 3);
  });
}

Chat _chat({required int id, required int unreadCount}) {
  return Chat(
    id: id,
    partner: UserSummary(id: id + 10, username: 'user$id'),
    createdAt: DateTime.parse('2026-05-18T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-18T09:30:00Z'),
    lastMessage: 'Hola',
    lastMessageTime: DateTime.parse('2026-05-18T09:30:00Z'),
    unreadCount: unreadCount,
    canSend: true,
    blockedByMe: false,
    blockedMe: false,
  );
}
