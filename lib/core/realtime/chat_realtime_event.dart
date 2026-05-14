import 'package:agendat/core/dto/chat_dto.dart';
import 'package:agendat/core/dto/message_dto.dart';
import 'package:agendat/core/mappers/chat_mapper.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';

abstract class ChatRealtimeEvent {
  const ChatRealtimeEvent({required this.type, required this.requestId});

  final String type;
  final String? requestId;

  factory ChatRealtimeEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    final requestId = json['request_id']?.toString();

    switch (type) {
      case 'message.created':
        return ChatMessageCreatedEvent(
          requestId: requestId,
          chatId: _parseChatId(json),
          chat: ChatDto.fromJson(_requiredMap(json, 'chat')).toDomain(),
          message: MessageDto.fromJson(
            _requiredMap(json, 'message'),
          ).toDomain(),
        );
      case 'message.read':
        return ChatMessagesReadEvent(
          requestId: requestId,
          chatId: _parseChatId(json),
          chat: ChatDto.fromJson(_requiredMap(json, 'chat')).toDomain(),
          messageIds: _parseMessageIds(json['message_ids']),
          readAt: _parseOptionalDateTime(json['read_at']),
        );
      case 'error':
        return ChatRealtimeErrorEvent(
          requestId: requestId,
          code: (json['code'] ?? 'unknown').toString(),
          message: (json['message'] ?? '').toString(),
        );
      default:
        throw FormatException('Unsupported chat realtime event: $type');
    }
  }

  static ChatRealtimeEvent? tryParse(Map<String, dynamic> json) {
    try {
      return ChatRealtimeEvent.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static int _parseChatId(Map<String, dynamic> json) {
    final explicit = json['chat_id'];
    if (explicit is num) return explicit.toInt();

    final chat = json['chat'];
    if (chat is Map<String, dynamic>) {
      final nested = chat['id_chat'] ?? chat['id'];
      if (nested is num) return nested.toInt();
    }

    throw const FormatException('Missing chat_id in chat realtime event.');
  }

  static Map<String, dynamic> _requiredMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    throw FormatException('Expected "$key" to be an object.');
  }

  static List<int> _parseMessageIds(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<num>().map((id) => id.toInt()).toList();
  }

  static DateTime? _parseOptionalDateTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

class ChatMessageCreatedEvent extends ChatRealtimeEvent {
  const ChatMessageCreatedEvent({
    required super.requestId,
    required this.chatId,
    required this.chat,
    required this.message,
  }) : super(type: 'message.created');

  final int chatId;
  final Chat chat;
  final ChatMessage message;
}

class ChatMessagesReadEvent extends ChatRealtimeEvent {
  const ChatMessagesReadEvent({
    required super.requestId,
    required this.chatId,
    required this.chat,
    required this.messageIds,
    required this.readAt,
  }) : super(type: 'message.read');

  final int chatId;
  final Chat chat;
  final List<int> messageIds;
  final DateTime? readAt;
}

class ChatRealtimeErrorEvent extends ChatRealtimeEvent {
  const ChatRealtimeErrorEvent({
    required super.requestId,
    required this.code,
    required this.message,
  }) : super(type: 'error');

  final String code;
  final String message;
}
