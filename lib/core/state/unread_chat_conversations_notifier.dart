import 'package:agendat/core/models/chat.dart';
import 'package:flutter/foundation.dart';

/// Nombre de converses amb almenys un missatge sense llegir (badge pestanya Social).
final ValueNotifier<int> unreadChatConversationsNotifier = ValueNotifier<int>(
  0,
);

void syncUnreadChatConversationsBadge(Iterable<Chat> chats) {
  unreadChatConversationsNotifier.value = chats
      .where((c) => c.unreadCount > 0)
      .length;
}
