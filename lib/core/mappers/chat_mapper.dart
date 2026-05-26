import 'package:agendat/core/dto/chat_dto.dart';
import 'package:agendat/core/dto/message_dto.dart';
import 'package:agendat/core/mappers/event_invitation_mapper.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/models/user_summary.dart';

extension ChatDtoMapper on ChatDto {
  Chat toDomain() {
    return Chat(
      id: id,
      partner: UserSummary.fromJson(partnerJson),
      createdAt: parseFlexibleDateTime(createdAt),
      updatedAt: parseFlexibleDateTime(updatedAt),
      lastMessage: lastMessage,
      lastMessageTime: parseFlexibleDateTime(updatedAt),
      unreadCount: unreadCount,
      canSend: canSend && !blockedMe && !blockedByMe,
      blockedByMe: blockedByMe,
      blockedMe: blockedMe,
    );
  }
}

extension MessageDtoMapper on MessageDto {
  ChatMessage toDomain() {
    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      content: content,
      type: type,
      fileUrl: fileUrl,
      sentAt: _parseDateTime(sentAt),
      edited: edited,
      readAt: _parseOptionalDateTime(readAt),
      isRead: isRead,
      eventInvitation: eventInvitation?.toDomain(),
    );
  }
}

DateTime _parseDateTime(String raw) {
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseOptionalDateTime(String? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw);
}
