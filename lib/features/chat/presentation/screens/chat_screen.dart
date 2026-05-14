import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/state/auth_session.dart';
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

  bool _loading = true;
  String? _error;
  List<Chat> _chats = const [];
  List<UserSummary> _friends = const [];
  bool _loadingFriends = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuth()) return;
      _reload(forceRefresh: true);
    });
  }

  @override
  void dispose() {
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

  /// Si és cert, després de nous missatges es fa scroll al final (missatges recents).
  bool _stickToBottom = true;

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ChatMessage> _messages = const [];
  late Chat _chat;

  UserSummary get _partner => _chat.partner;
  int? get _myUserId => currentLoggedInUser?['id'] as int?;

  static const String _inactiveUnfriendBanner =
      'Ja no sou amics amb aquest usuari. El xat es manté al llistat però '
      'només pots llegir els missatges anteriors.';

  static const String _inactiveBlockedByPartnerBanner =
      'Aquest usuari t\'ha bloquejat. El xat es manté al llistat però '
      'només pots llegir els missatges anteriors.';

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

  Future<void> _sendMessage() async {
    final myUserId = _myUserId;
    final text = _inputController.text.trim();
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
              onSend: _sendMessage,
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
        return Message(
          messageText: message.content.isEmpty
              ? '(sense text)'
              : message.content,
          sentAt: message.sentAt,
          isSentByMe: isMine,
          avatarUrl: isMine ? myProfileImage : _partner.profileImage,
          avatarLabel: isMine ? (_myAvatarLabel ?? '?') : _partner.displayName,
        );
      },
    );
  }
}
