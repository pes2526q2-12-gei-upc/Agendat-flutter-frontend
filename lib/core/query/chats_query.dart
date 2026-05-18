import 'package:agendat/core/api/chats_api.dart';
import 'package:agendat/core/mappers/chat_mapper.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/query/profile_query.dart';

export 'package:agendat/core/api/chats_api.dart'
    show ChatMessageType, SendMessageRequest;

class ChatsQuery {
  static final ChatsQuery instance = ChatsQuery._();
  ChatsQuery._();

  static const Duration staleTime = Duration(minutes: 1);
  static const String _prefix = 'chats';

  final ChatsApi _api = ChatsApi();
  final QueryClient _client = QueryClient.instance;
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  /// Omple `partner.profileImage` des de la caché / GET perfil quan el xat no en porta.
  Future<List<Chat>> _hydratePartnerAvatars(List<Chat> chats) async {
    final needIds = chats
        .where((c) {
          final img = c.partner.profileImage?.trim();
          return img == null || img.isEmpty;
        })
        .map((c) => c.partner.id)
        .toSet();
    if (needIds.isEmpty) return chats;

    final imageByUserId = <int, String>{};
    for (final userId in needIds) {
      try {
        final result = await _profileQuery.getUserProfile(
          userId,
          forceRefresh: false,
        );
        if (result is ProfileSuccess) {
          final url = result.profile.profileImage?.trim();
          if (url != null && url.isNotEmpty) imageByUserId[userId] = url;
        }
      } catch (_) {
        // Best effort: el xat es mostra sense foto.
      }
    }
    if (imageByUserId.isEmpty) return chats;

    return chats.map((c) {
      final url = imageByUserId[c.partner.id];
      if (url == null) return c;
      return c.copyWith(partner: c.partner.copyWith(profileImage: url));
    }).toList();
  }

  /// Llista de xats deduïda de la darrera caché, sense xarxa. Útil per sincronitzar
  /// pantalles montades permanentment amb mutacions òptimes.
  List<Chat>? peekCachedChatsList() =>
      _client.getQueryData<List<Chat>>(_listKey);

  Future<List<Chat>> getChats({bool forceRefresh = false}) {
    return _client.query<List<Chat>>(
      key: _listKey,
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchChats();
        final chats = dtos.map((dto) => dto.toDomain()).toList();
        return _hydratePartnerAvatars(chats);
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
        final chat = dto.toDomain();
        final hydrated = await _hydratePartnerAvatars([chat]);
        return hydrated.first;
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

  Future<void> markRead(int chatId) async {
    await _api.markRead(chatId);
    _client.invalidate(_detailKey(chatId));
    _client.invalidate(_listKey);
    _client.invalidate(_messagesKey(chatId));
  }

  void applyRealtimeEvent(ChatRealtimeEvent event) {
    switch (event) {
      case ChatMessageCreatedEvent():
        _upsertChatSummary(event.chat);
        _appendMessageToCache(event.chatId, event.message);
      case ChatMessagesReadEvent():
        _upsertChatSummary(event.chat);
        _markMessagesReadInCache(event.chatId, event.messageIds, event.readAt);
      case ChatRealtimeErrorEvent():
        break;
    }
  }

  void invalidateAll() => _client.invalidatePrefix(_prefix);

  /// Força un refetch de la llista de xats (p. ex. després de desbloquejar un usuari).
  void invalidateChatsList() => _client.invalidate(_listKey);

  /// Treu de la caché del llistat el xat amb [partnerUserId] (p. ex. després de
  /// bloquejar l’altre: el xat s’elimina de la llista al client).
  void removePartnerChatFromListCache(int partnerUserId) {
    final cached = _client.getQueryData<List<Chat>>(_listKey);
    if (cached == null) return;

    final toRemove = cached
        .where((c) => c.partner.id == partnerUserId)
        .toList();
    if (toRemove.isEmpty) return;

    final next = cached.where((c) => c.partner.id != partnerUserId).toList();
    _client.setQueryData(_listKey, next);
    syncUnreadChatConversationsBadge(next);

    for (final c in toRemove) {
      _client.invalidate(_detailKey(c.id));
      _client.invalidate(_messagesKey(c.id));
    }
  }

  void invalidateChat(int chatId) {
    _client.invalidate(_detailKey(chatId));
    _client.invalidate(_messagesKey(chatId));
    _client.invalidate(_listKey);
  }

  void _upsertChatSummary(Chat chat) {
    if (!chat.blockedByMe) {
      _client.setQueryData(_detailKey(chat.id), chat);
    } else {
      _client.invalidate(_detailKey(chat.id));
    }

    final cached = _client.getQueryData<List<Chat>>(_listKey);
    if (cached == null) return;

    final withoutCurrent = cached.where((item) => item.id != chat.id).toList();
    final next = chat.blockedByMe ? withoutCurrent : [chat, ...withoutCurrent];
    next.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
    _client.setQueryData(_listKey, next);
    syncUnreadChatConversationsBadge(next);
  }

  void _appendMessageToCache(int chatId, ChatMessage message) {
    final cached = _client.getQueryData<List<ChatMessage>>(
      _messagesKey(chatId),
    );
    if (cached == null) return;

    // Upsert: si el missatge ja existeix (mateix `id`), el substituïm pel
    // payload actualitzat. Això és crític per al cicle de vida d'invitacions
    // a esdeveniments, on el backend reemet `message.created` amb el mateix
    // `message_id` però amb el camp `event_invitation.status` actualitzat
    // (per exemple, quan el destinatari accepta o rebutja).
    final existingIndex = cached.indexWhere((item) => item.id == message.id);
    if (existingIndex >= 0) {
      final next = [...cached];
      next[existingIndex] = message;
      _client.setQueryData(_messagesKey(chatId), next);
      return;
    }

    final next = [...cached, message]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    _client.setQueryData(_messagesKey(chatId), next);
  }

  /// Actualització optimista local del payload `eventInvitation` d'un
  /// missatge concret a la cache de missatges del xat. Útil per reflectir
  /// instantàniament l'efecte d'acceptar/rebutjar una invitació, abans que
  /// arribi el `message.created` re-emès pel backend via WebSocket.
  void upsertInvitationStatusInMessage({
    required int chatId,
    required int messageId,
    required EventInvitation invitation,
  }) {
    final cached = _client.getQueryData<List<ChatMessage>>(
      _messagesKey(chatId),
    );
    if (cached == null) return;

    final index = cached.indexWhere((message) => message.id == messageId);
    if (index < 0) return;

    final current = cached[index];
    if (current.eventInvitation?.status == invitation.status &&
        current.eventInvitation?.respondedAt == invitation.respondedAt) {
      return;
    }

    final next = [...cached];
    next[index] = current.copyWith(eventInvitation: invitation);
    _client.setQueryData(_messagesKey(chatId), next);
  }

  void _markMessagesReadInCache(
    int chatId,
    List<int> messageIds,
    DateTime? readAt,
  ) {
    if (messageIds.isEmpty) return;

    final cached = _client.getQueryData<List<ChatMessage>>(
      _messagesKey(chatId),
    );
    if (cached == null) return;

    final ids = messageIds.toSet();
    var changed = false;
    final next = cached.map((message) {
      if (!ids.contains(message.id)) return message;

      final nextReadAt = readAt ?? message.readAt;
      if (message.isRead && message.readAt == nextReadAt) {
        return message;
      }

      changed = true;
      return message.copyWith(isRead: true, readAt: nextReadAt);
    }).toList();

    if (!changed) return;
    _client.setQueryData(_messagesKey(chatId), next);
  }

  /// Actualitza només la caché local del llistat de xats: quan canvii
  /// l'amistat, el backend pot retornar el mateix xat amb `can_send` false
  /// sense eliminar-lo. Això manté coherència fins al proper refetch remot.
  void syncPartnerMessagingInChatListCache(
    int partnerUserId, {
    required bool canSendMessages,
  }) {
    final cached = _client.getQueryData<List<Chat>>(_listKey);
    if (cached == null) return;

    var changed = false;
    final next = cached.map((c) {
      if (c.partner.id != partnerUserId) return c;
      if (c.canSend == canSendMessages) return c;
      changed = true;
      return c.copyWith(canSend: canSendMessages);
    }).toList();

    if (!changed) return;

    _client.setQueryData(_listKey, next);
    syncUnreadChatConversationsBadge(next);

    for (final c in next) {
      if (c.partner.id == partnerUserId) {
        _client.invalidate(_detailKey(c.id));
      }
    }
  }

  String get _listKey => '$_prefix:list';
  String _detailKey(int chatId) => '$_prefix:detail:$chatId';
  String _messagesKey(int chatId) => '$_prefix:messages:$chatId';
}
