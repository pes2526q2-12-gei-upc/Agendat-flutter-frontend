import 'package:agendat/core/models/chat.dart';
import 'package:flutter/foundation.dart';

/// Nombre de missatges sense llegir (badge pestanya Social).
final ValueNotifier<int> unreadChatConversationsNotifier = ValueNotifier<int>(
  0,
);

void syncUnreadChatConversationsBadge(Iterable<Chat> chats) {
  unreadChatConversationsNotifier.value = chats.fold<int>(
    0,
    (total, chat) => total + (chat.unreadCount > 0 ? chat.unreadCount : 0),
  );
}
