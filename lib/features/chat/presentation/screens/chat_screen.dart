import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/chat_message.dart';
import 'package:agendat/core/api/chats_api.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/chat/presentation/widgets/chatRow.dart';
import 'package:agendat/features/chat/presentation/widgets/message.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
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

  void _openChat(Chat chat) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendConversationScreen(chat: chat),
      ),
    );
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
          _emptyPane(
            icon: Icons.error_outline,
            title: _error!,
            action: ('Reintentar', () => _reload(forceRefresh: true)),
          ),
        ],
      );
    }

    if (_chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _emptyPane(
            icon: Icons.chat_bubble_outline,
            title: 'Encara no tens cap xat.',
            subtitle: 'Pots iniciar una conversa amb qualsevol amic.',
          ),
          const SizedBox(height: 12),
          ..._buildFriendsStarters(),
        ],
      );
    }

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _emptyPane(
            icon: Icons.search_off,
            title: 'Cap xat coincideix amb la cerca.',
            subtitle:
                'Prova un altre nom o esborra el text per veure tots els xats.',
            action: ('Esborra cerca', _clearSearch),
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

  Widget _emptyPane({
    required IconData icon,
    required String title,
    String? subtitle,
    (String, VoidCallback)? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: action.$2,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: Colors.white,
              ),
              child: Text(action.$1),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildFriendsStarters() {
    if (_loadingFriends) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_friends.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 4),
          child: Center(
            child: Text(
              'No tens amics disponibles per iniciar un xat.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ];
    }

    final sorted = [..._friends]
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    return [
      Text(
        'Inicia xat amb amics',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade800,
        ),
      ),
      const SizedBox(height: 10),
      ...sorted.map(
        (friend) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(
                chatAvatarInitials(friend.displayName),
                style: const TextStyle(color: Colors.black54),
              ),
            ),
            title: Text(
              friend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '@${friend.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chat_outlined),
            onTap: () => _startChatWithFriend(friend),
          ),
        ),
      ),
    ];
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
  final _chatsQuery = ChatsQuery.instance;
  final _inputController = TextEditingController();
  final _inputFocus = FocusNode();

  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<ChatMessage> _messages = const [];

  UserSummary get _partner => widget.chat.partner;
  int? get _myUserId => currentLoggedInUser?['id'] as int?;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload(forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _reload({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await _chatsQuery.getMessages(
        widget.chat.id,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _loading = false;
      });
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
    if (text.isEmpty || _sending || myUserId == null) return;

    setState(() => _sending = true);
    try {
      await _chatsQuery.sendMessage(
        widget.chat.id,
        request: SendMessageRequest(content: text),
      );
      _inputController.clear();
      _inputFocus.requestFocus();
      await _reload(forceRefresh: true);
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

  @override
  Widget build(BuildContext context) {
    final photoUrl = chatProfileImageUrl(_partner.profileImage);
    final messages = _messages;

    return Scaffold(
      backgroundColor: AppThemeTokens.screenBackground,
      appBar: AppBar(
        backgroundColor: AppThemeTokens.appBarBackground,
        elevation: AppThemeTokens.appBarElevation,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Text(
                      chatAvatarInitials(_partner.displayName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _partner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '@${_partner.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _inputFocus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Escriu un missatge...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
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
        children: const [
          SizedBox(height: 120),
          Center(
            child: Text(
              'Encara no hi ha missatges. Envia el primer.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      reverse: true,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        final isMine = message.senderId == _myUserId;
        final myProfileImage = currentLoggedInUser == null
            ? null
            : currentLoggedInUser!['profile_image'] as String?;
        final myUsername = currentLoggedInUser == null
            ? null
            : currentLoggedInUser!['username'] as String?;
        return Message(
          messageText: message.content.isEmpty
              ? '(sense text)'
              : message.content,
          sentAt: message.sentAt,
          isSentByMe: isMine,
          avatarUrl: isMine ? myProfileImage : _partner.profileImage,
          avatarLabel: isMine ? myUsername : _partner.displayName,
        );
      },
    );
  }
}
