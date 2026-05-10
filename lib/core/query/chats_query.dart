import 'package:agendat/core/api/chats_api.dart';
import 'package:agendat/core/mappers/chat_mapper.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/query/query_client.dart';

class ChatsQuery {
  static final ChatsQuery instance = ChatsQuery._();
  ChatsQuery._();

  static const Duration staleTime = Duration(minutes: 1);
  static const String _prefix = 'chats';

  final ChatsApi _api = ChatsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<Chat>> getChats({bool forceRefresh = false}) {
    return _client.query<List<Chat>>(
      key: _listKey,
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchChats();
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<Chat> getChat(int chatId, {bool forceRefresh = false}) {
    return _client.query<Chat>(
      key: _detailKey(chatId),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dto = await _api.fetchChat(chatId);
        return dto.toDomain();
      },
    );
  }

  Future<List<ChatMessage>> getMessages(
    int chatId, {
    bool forceRefresh = false,
  }) {
    return _client.query<List<ChatMessage>>(
      key: _messagesKey(chatId),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchMessages(chatId);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<ChatMessage> sendMessage(
    int chatId, {
    required SendMessageRequest request,
  }) async {
    final dto = await _api.sendMessage(chatId, request);
    final sent = dto.toDomain();

    // Keep message lists and chat summaries fresh after any mutation.
    _client.invalidate(_messagesKey(chatId));
    _client.invalidate(_detailKey(chatId));
    _client.invalidate(_listKey);

    return sent;
  }

  void invalidateAll() => _client.invalidatePrefix(_prefix);

  void invalidateChat(int chatId) {
    _client.invalidate(_detailKey(chatId));
    _client.invalidate(_messagesKey(chatId));
    _client.invalidate(_listKey);
  }

  String get _listKey => '$_prefix:list';
  String _detailKey(int chatId) => '$_prefix:detail:$chatId';
  String _messagesKey(int chatId) => '$_prefix:messages:$chatId';
}
