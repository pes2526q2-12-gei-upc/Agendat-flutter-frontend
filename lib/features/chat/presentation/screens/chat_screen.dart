import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/state/auth_session.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/realtime/chat_realtime_service.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/chat/presentation/widgets/chatRow.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_empty_pane.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_friends_starters.dart';
import 'package:agendat/features/chat/presentation/widgets/conversation_message_input_bar.dart';
import 'package:agendat/features/chat/presentation/widgets/conversation_partner_app_bar_title.dart';
import 'package:agendat/features/chat/presentation/widgets/event_invitation_message.dart';
import 'package:agendat/features/chat/presentation/widgets/inactive_conversation_banner.dart';
import 'package:agendat/features/chat/presentation/widgets/message.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Pantalla de llista de xats (dades reals des de backend via [ChatsQuery]).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _accentRed = Color(0xFFB71C1C);

  final _chatsQuery = ChatsQuery.instance;
  final _profileQuery = ProfileQuery.instance;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  StreamSubscription<ChatRealtimeEvent>? _realtimeSubscription;

  bool _loading = true;
  String? _error;
  List<Chat> _chats = const [];
  List<UserSummary> _friends = const [];
  bool _loadingFriends = false;

  @override
  void initState() {
    super.initState();
    _realtimeSubscription = ChatRealtimeService.instance.events.listen(
      _onRealtimeEvent,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuth()) return;
      _reload(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool get _authenticated =>
      currentAuthToken != null &&
      currentAuthToken!.trim().isNotEmpty &&
      currentLoggedInUser?['id'] is int;

  bool _guardAuth() {
    if (_authenticated || !mounted) return _authenticated;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cal iniciar sessió per veure els teus xats.'),
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    return false;
  }

  List<Chat> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _chats;
    return _chats.where((c) {
      final p = c.partner;
      return p.displayName.toLowerCase().contains(q) ||
          p.username.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _reload({bool forceRefresh = false}) async {
    if (!_guardAuth()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final chats = await _chatsQuery.getChats(forceRefresh: forceRefresh);
      final myId = currentLoggedInUser?['id'];
      List<UserSummary> friends = _friends;
      if (myId is int) {
        _loadingFriends = true;
        try {
          friends = await _profileQuery.getFriends(
            myId,
            forceRefresh: forceRefresh,
          );
        } catch (_) {
          // Best effort: si falla, mantenim la darrera llista d'amics.
          friends = _friends;
        } finally {
          _loadingFriends = false;
        }
      }
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _friends = friends;
        _loading = false;
      });
      syncUnreadChatConversationsBadge(chats);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[chat_screen] load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No s\'ha pogut carregar els xats. Comprova la connexió.';
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {});
    _searchFocus.unfocus();
  }

  void _onRealtimeEvent(ChatRealtimeEvent event) {
    if (!mounted) return;
    _chatsQuery.applyRealtimeEvent(event);
    switch (event) {
      case ChatMessageCreatedEvent():
        _syncChatsFromCache();
      case ChatMessagesReadEvent():
        _syncChatsFromCache();
      case ChatRealtimeErrorEvent():
        break;
    }
  }

  void _syncChatsFromCache() {
    final cached = _chatsQuery.peekCachedChatsList();
    if (cached == null) return;
    setState(() => _chats = cached);
    syncUnreadChatConversationsBadge(cached);
  }

  Future<void> _openChat(Chat chat) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FriendConversationScreen(chat: chat),
      ),
    );
    if (!mounted) return;
    await _reload(forceRefresh: true);
  }

  Future<void> _startChatWithFriend(UserSummary friend) async {
    try {
      final refreshedChats = await _chatsQuery.getChats(forceRefresh: true);
      Chat? chat;
      for (final candidate in refreshedChats) {
        if (candidate.partner.id == friend.id) {
          chat = candidate;
          break;
        }
      }
      if (chat == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aquest xat encara no està disponible. Torna-ho a provar en uns segons.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _chats = refreshedChats);
      _openChat(chat);
    } catch (e, st) {
      if (kDebugMode) debugPrint('[chat_screen] start chat failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No s\'ha pogut obrir el xat amb aquest amic.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: AppThemeTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: AppThemeTokens.appBarBackground,
        elevation: AppThemeTokens.appBarElevation,
        foregroundColor: Colors.black87,
        title: Text('Xats', style: AppThemeTokens.appBarTitle),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppScreenSpacing.horizontal,
              AppScreenSpacing.xs,
              AppScreenSpacing.horizontal,
              AppScreenSpacing.xxs,
            ),
            child: AppSearchBar(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              hintText: 'Cerca un xat',
              margin: EdgeInsets.zero,
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Esborra',
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: _clearSearch,
                    ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _accentRed,
              onRefresh: () => _reload(forceRefresh: true),
              child: _body(list),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(List<Chat> list) {
    if (_loading && _chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          ChatEmptyPane(
            icon: Icons.error_outline,
            title: _error!,
            actionLabel: 'Reintentar',
            onAction: () => _reload(forceRefresh: true),
            accentColor: _accentRed,
          ),
        ],
      );
    }

    if (_chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          ChatEmptyPane(
            icon: Icons.chat_bubble_outline,
            title: 'Encara no tens cap xat.',
            subtitle: 'Pots iniciar una conversa amb qualsevol amic.',
            accentColor: _accentRed,
          ),
          const SizedBox(height: 12),
          ChatFriendsStarters(
            loading: _loadingFriends,
            friends: _friends,
            onFriendTap: _startChatWithFriend,
          ),
        ],
      );
    }

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          ChatEmptyPane(
            icon: Icons.search_off,
            title: 'Cap xat coincideix amb la cerca.',
            subtitle:
                'Prova un altre nom o esborra el text per veure tots els xats.',
            actionLabel: 'Esborra cerca',
            onAction: _clearSearch,
            accentColor: _accentRed,
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppScreenSpacing.horizontal,
        AppScreenSpacing.xxs,
        AppScreenSpacing.horizontal,
        AppScreenSpacing.bottom,
      ),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppScreenSpacing.xs),
      itemBuilder: (context, i) {
        final chat = list[i];
        return ClipRRect(
          key: ValueKey<int>(chat.id),
          borderRadius: BorderRadius.circular(12),
          child: ChatRow(chat: chat, onTap: () => _openChat(chat)),
        );
      },
    );
  }
}

/// Pantalla de conversa amb càrrega real de missatges.
class FriendConversationScreen extends StatefulWidget {
  const FriendConversationScreen({super.key, required this.chat});

  final Chat chat;

  @override
  State<FriendConversationScreen> createState() =>
      _FriendConversationScreenState();
}

class _FriendConversationScreenState extends State<FriendConversationScreen> {
  static const double _stickToBottomThreshold = 80;

  final _chatsQuery = ChatsQuery.instance;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();
  final _listScrollController = ScrollController();
  final _imagePicker = ImagePicker();
  StreamSubscription<ChatRealtimeEvent>? _realtimeSubscription;
  StreamSubscription<FriendshipChange>? _friendshipChangeSubscription;

  /// Si és cert, després de nous missatges es fa scroll al final (missatges recents).
  bool _stickToBottom = true;

  bool _loading = true;
  bool _sending = false;
  bool _pickingImage = false;
  String? _error;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;
  List<ChatMessage> _messages = const [];
  late Chat _chat;

  UserSummary get _partner => _chat.partner;
  int? get _myUserId {
    final raw = currentLoggedInUser?['id'];
    if (raw is num) return raw.toInt();
    return null;
  }

  static const String _inactiveUnfriendBanner =
      'Ja no sou amics amb aquest usuari. El xat es manté al llistat però '
      'només pots llegir els missatges anteriors.';

  static const String _inactiveBlockedByPartnerBanner =
      'Aquest usuari t\'ha bloquejat. El xat es manté al llistat però '
      'només pots llegir els missatges anteriors.';

  static const Set<String> _allowedImageExtensions = {'jpg', 'jpeg', 'png'};

  String _inactiveConversationBannerText() {
    if (_chat.blockedByMe) {
      return 'Has bloquejat aquest usuari. El xat ja no apareix al llistat de '
          'converses.';
    }
    if (_chat.blockedMe) {
      return _inactiveBlockedByPartnerBanner;
    }
    return _inactiveUnfriendBanner;
  }

  String? get _myAvatarLabel {
    final u = currentLoggedInUser;
    if (u == null) return null;
    final fn = u['first_name'] as String?;
    final ln = u['last_name'] as String?;
    final parts = [
      fn,
      ln,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return u['username'] as String?;
  }

  @override
  void initState() {
    super.initState();
    _chat = widget.chat;
    _listScrollController.addListener(_onMessagesScroll);
    _realtimeSubscription = ChatRealtimeService.instance.events.listen(
      _onRealtimeEvent,
    );
    _friendshipChangeSubscription = ProfileQuery.instance.friendshipChanges
        .listen(_onFriendshipChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload(
        forceRefresh: true,
        scrollToNewest: true,
        animateScrollToNewest: false,
      );
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _friendshipChangeSubscription?.cancel();
    _listScrollController.removeListener(_onMessagesScroll);
    _listScrollController.dispose();
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onMessagesScroll() {
    if (!_listScrollController.hasClients) return;
    final pos = _listScrollController.position;
    final distFromBottom = pos.maxScrollExtent - pos.pixels;
    _stickToBottom = distFromBottom <= _stickToBottomThreshold;
  }

  void _scrollMessagesToBottom({bool animated = false}) {
    void jump() {
      if (!mounted || !_listScrollController.hasClients) return;
      final maxExtent = _listScrollController.position.maxScrollExtent;
      if (animated) {
        _listScrollController.animateTo(
          maxExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _listScrollController.jumpTo(maxExtent);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => jump());
    });
  }

  void _onRealtimeEvent(ChatRealtimeEvent event) {
    if (!mounted) return;
    _chatsQuery.applyRealtimeEvent(event);

    switch (event) {
      case ChatMessageCreatedEvent():
        if (event.chatId != widget.chat.id) return;
        final shouldScrollToNewest =
            _stickToBottom || event.message.senderId == _myUserId;
        final existingIndex = _messages.indexWhere(
          (message) => message.id == event.message.id,
        );
        setState(() {
          _chat = event.chat;
          if (existingIndex >= 0) {
            final next = [..._messages];
            next[existingIndex] = event.message;
            _messages = next;
          } else {
            _messages = [..._messages, event.message]
              ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
          }
          _loading = false;
        });
        if (shouldScrollToNewest) {
          _scrollMessagesToBottom(animated: true);
        }
        if (event.message.senderId != _myUserId) {
          unawaited(_chatsQuery.markRead(event.chatId));
        }
      case ChatMessagesReadEvent():
        if (event.chatId != widget.chat.id) return;
        setState(() {
          _chat = event.chat;
          _messages = _applyReadReceiptEvent(_messages, event);
        });
      case ChatRealtimeErrorEvent():
        break;
    }
  }

  void _onFriendshipChange(FriendshipChange change) {
    if (!mounted || change.counterpartId != _partner.id) return;
    _refreshChatFromCache();
  }

  List<ChatMessage> _applyReadReceiptEvent(
    List<ChatMessage> messages,
    ChatMessagesReadEvent event,
  ) {
    if (event.messageIds.isEmpty) return messages;

    final ids = event.messageIds.toSet();
    return messages.map((message) {
      if (!ids.contains(message.id)) return message;
      return message.copyWith(
        isRead: true,
        readAt: event.readAt ?? message.readAt,
      );
    }).toList();
  }

  Future<void> _reload({
    bool forceRefresh = false,
    bool? scrollToNewest,
    bool animateScrollToNewest = false,
  }) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      Chat refreshedChat = _chat;
      try {
        refreshedChat = await _chatsQuery.getChat(
          widget.chat.id,
          forceRefresh: forceRefresh,
        );
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[friend_conversation] getChat: $e\n$st');
        }
      }

      final messages = await _chatsQuery.getMessages(
        widget.chat.id,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final shouldScrollToNewest = scrollToNewest ?? _stickToBottom;
      setState(() {
        _chat = refreshedChat;
        _messages = messages;
        _loading = false;
        if (scrollToNewest == true) {
          _stickToBottom = true;
        }
      });
      if (shouldScrollToNewest && messages.isNotEmpty) {
        _scrollMessagesToBottom(animated: animateScrollToNewest);
      }
      try {
        await _chatsQuery.markRead(widget.chat.id);
      } catch (e, st) {
        if (kDebugMode) debugPrint('[friend_conversation] markRead: $e\n$st');
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[friend_conversation] load: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No s\'han pogut carregar els missatges.';
      });
    }
  }

  void _refreshChatFromCache() {
    final cached = _chatsQuery.peekCachedChat(widget.chat.id);
    if (cached == null || !mounted) return;
    setState(() {
      _chat = cached;
      _error = null;
    });
  }

  Future<void> _sendMessage() async {
    final myUserId = _myUserId;
    final text = _inputController.text.trim();
    final selectedImage = _selectedImage;
    final selectedImageBytes = _selectedImageBytes;
    final selectedImageExtension = _selectedImageExtension;

    if (selectedImage != null &&
        selectedImageBytes != null &&
        selectedImageExtension != null) {
      if (_sending || myUserId == null || !_chat.canSend) {
        if (!_chat.canSend && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aquest xat està inactiu. Només podeu llegir la conversa.',
              ),
            ),
          );
        }
        return;
      }

      setState(() => _sending = true);
      try {
        await _sendImageBytes(
          bytes: selectedImageBytes,
          filename: _normalizedImageFilename(
            selectedImage,
            selectedImageExtension,
          ),
          contentType: _contentTypeForImageExtension(selectedImageExtension),
        );
        _clearSelectedImage();
      } catch (e, st) {
        if (kDebugMode) debugPrint('[friend_conversation] send image: $e\n$st');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_sendImageErrorMessage(e))));
      } finally {
        if (mounted) {
          setState(() => _sending = false);
        }
      }
      return;
    }

    if (text.isEmpty || _sending || myUserId == null || !_chat.canSend) {
      if (text.isNotEmpty && !_chat.canSend && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aquest xat està inactiu. Només podeu llegir la conversa.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _sending = true);
    try {
      await _chatsQuery.sendMessage(
        _chat.id,
        request: SendMessageRequest(content: text),
      );
      _inputController.clear();
      _inputFocus.requestFocus();
      await _reload(
        forceRefresh: true,
        scrollToNewest: true,
        animateScrollToNewest: true,
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[friend_conversation] send: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut enviar el missatge.')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final myUserId = _myUserId;
    final text = _inputController.text;
    if (_sending ||
        _pickingImage ||
        text.isNotEmpty ||
        myUserId == null ||
        !_chat.canSend) {
      if (!_chat.canSend && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aquest xat està inactiu. Només podeu llegir la conversa.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _pickingImage = true);
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 82,
      );
      if (picked == null) return;

      final extension = _allowedImageExtension(picked);
      if (extension == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Només es poden enviar imatges JPG, JPEG o PNG.'),
          ),
        );
        return;
      }

      final bytes = await picked.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La imatge seleccionada és buida.')),
        );
        return;
      }

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _selectedImageExtension = extension;
      });
      _inputFocus.unfocus();
    } catch (e, st) {
      if (kDebugMode) debugPrint('[friend_conversation] pick image: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut seleccionar la imatge.')),
      );
    } finally {
      if (mounted) {
        setState(() => _pickingImage = false);
      }
    }
  }

  Future<void> _sendImageBytes({
    required Uint8List bytes,
    required String filename,
    required String contentType,
  }) async {
    await _chatsQuery.sendImageMessage(
      _chat.id,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
      content: '',
    );
    _inputController.clear();
    _inputFocus.requestFocus();
    await _reload(
      forceRefresh: true,
      scrollToNewest: true,
      animateScrollToNewest: true,
    );
  }

  String? _allowedImageExtension(XFile image) {
    final name = image.name.trim().isNotEmpty ? image.name : image.path;
    final dot = name.lastIndexOf('.');
    final extension = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
    if (_allowedImageExtensions.contains(extension)) return extension;

    switch (image.mimeType?.toLowerCase()) {
      case 'image/jpeg':
        return 'jpg';
      case 'image/png':
        return 'png';
    }
    return null;
  }

  String _normalizedImageFilename(XFile image, String extension) {
    final rawName = image.name.trim().isNotEmpty ? image.name.trim() : '';
    if (rawName.isEmpty) return 'chat-image.$extension';
    final lowerName = rawName.toLowerCase();
    if (_allowedImageExtensions.any((ext) => lowerName.endsWith('.$ext'))) {
      return rawName;
    }
    return '$rawName.$extension';
  }

  String _contentTypeForImageExtension(String extension) {
    return extension == 'png' ? 'image/png' : 'image/jpeg';
  }

  String _sendImageErrorMessage(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 413) {
        return 'La imatge és massa gran. Prova amb una imatge més petita.';
      }
      if (error.statusCode >= 500) {
        return 'El servidor no ha pogut pujar la imatge. Torna-ho a provar.';
      }
    }
    return 'No s\'ha pogut enviar la imatge.';
  }

  void _clearSelectedImage() {
    if (!mounted) return;
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageExtension = null;
    });
  }

  void _openPartnerProfile() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ProfileScreen(userId: _partner.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages;

    return Scaffold(
      backgroundColor: AppThemeTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: AppThemeTokens.appBarBackground,
        elevation: AppThemeTokens.appBarElevation,
        foregroundColor: Colors.black87,
        title: ConversationPartnerAppBarTitle(
          partner: _partner,
          onTap: _openPartnerProfile,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _reload(forceRefresh: true),
              child: _buildMessagesBody(messages),
            ),
          ),
          if (_chat.canSend)
            ConversationMessageInputBar(
              controller: _inputController,
              focusNode: _inputFocus,
              sending: _sending,
              pickingImage: _pickingImage,
              selectedImageBytes: _selectedImageBytes,
              onSend: _sendMessage,
              onPickImage: _pickImage,
              onRemoveImage: _clearSelectedImage,
            )
          else
            InactiveConversationBanner(
              message: _inactiveConversationBannerText(),
            ),
        ],
      ),
    );
  }

  Widget _buildMessagesBody(List<ChatMessage> messages) {
    if (_loading && messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
        ],
      );
    }

    if (messages.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Text(
              _chat.canSend
                  ? 'Encara no hi ha missatges. Envia el primer.'
                  : 'Encara no hi ha missatges en aquest xat.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    final orderedMessages = [...messages]
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    final latestSentMessageId = _latestSentMessageId(orderedMessages);

    return ListView.builder(
      controller: _listScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      itemCount: orderedMessages.length,
      itemBuilder: (context, index) {
        final message = orderedMessages[index];
        final isMine = message.senderId == _myUserId;
        final myProfileImage = currentLoggedInUser == null
            ? null
            : currentLoggedInUser!['profile_image'] as String?;

        if (message.isEventInvitation) {
          return EventInvitationMessage(
            invitation: message.eventInvitation!,
            messageId: message.id,
            chatId: message.chatId,
            sentAt: message.sentAt,
            isSentByMe: isMine,
            partner: _partner,
            myAvatarUrl: myProfileImage,
            myAvatarLabel: _myAvatarLabel,
            onInvitationUpdated: (updated) {
              setState(() {
                _messages = _messages
                    .map(
                      (m) => m.id == message.id
                          ? m.copyWith(eventInvitation: updated)
                          : m,
                    )
                    .toList();
              });
            },
          );
        }

        return Message(
          key: ValueKey<int>(message.id),
          messageText: message.content.isEmpty && message.type != 'image'
              ? '(sense text)'
              : message.content,
          imageUrl: message.type == 'image' ? message.fileUrl : null,
          sentAt: message.sentAt,
          isSentByMe: isMine,
          avatarUrl: isMine ? myProfileImage : _partner.profileImage,
          avatarLabel: isMine ? (_myAvatarLabel ?? '?') : _partner.displayName,
          receiptLabel: isMine && message.id == latestSentMessageId
              ? (message.isRead ? 'Llegit' : 'Enviat')
              : null,
        );
      },
    );
  }

  int? _latestSentMessageId(List<ChatMessage> messages) {
    final myUserId = _myUserId;
    if (myUserId == null) return null;

    for (final message in messages.reversed) {
      if (message.senderId == myUserId) {
        return message.id;
      }
    }
    return null;
  }
}
