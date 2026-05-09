import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/chat/presentation/widgets/chatRow.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Llista de xats construïda a partir dels **amics** fins que existeixi API de converses (`ChatsApi`).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _accentRed = Color(0xFFB71C1C);

  final _profileQuery = ProfileQuery.instance;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  bool _loading = true;
  String? _error;
  List<Chat> _chats = const [];

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

  /// Construeix un [Chat] per amic (`Chat.id` = id de l’amic fins que hi hagi xat real al backend).
  static List<Chat> _chatsFromFriends(List<UserSummary> friends) {
    final sorted = [...friends]
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    final now = DateTime.now();
    return [
      for (final f in sorted)
        Chat(
          id: f.id,
          partner: f,
          lastMessage: 'Sense missatges encara',
          lastMessageTime: now,
          unreadCount: 0,
        ),
    ];
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
    final myId = currentLoggedInUser!['id'] as int;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final friends = await _profileQuery.getFriends(
        myId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _chats = _chatsFromFriends(friends);
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

  void _openChat(UserSummary partner) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FriendConversationScreen(partner: partner),
      ),
    );
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
              hintText: 'Cerca un amic per obrir el xat',
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
            icon: Icons.handshake_outlined,
            title: 'Encara no tens amics.',
            subtitle:
                'Afegeix amics des de Social per poder xatejar amb ells aquí.',
          ),
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
            title: 'Cap amic coincideix amb la cerca.',
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
          child: ChatRow(chat: chat, onTap: () => _openChat(chat.partner)),
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
}

/// Pantalla de conversa (contingut real quan hi hagi backend de xat).
class FriendConversationScreen extends StatelessWidget {
  const FriendConversationScreen({super.key, required this.partner});

  final UserSummary partner;

  @override
  Widget build(BuildContext context) {
    final photoUrl = chatProfileImageUrl(partner.profileImage);
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
                      chatAvatarInitials(partner.displayName),
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
                    partner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '@${partner.username}',
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 72,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Conversa amb ${partner.displayName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí es mostraran els missatges quan el servidor de xats estigui disponible.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
