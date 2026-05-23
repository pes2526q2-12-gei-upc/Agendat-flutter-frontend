import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/state/auth_session.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/realtime/chat_realtime_service.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/core/widgets/require_auth.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_row.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_empty_pane.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_friends_starters.dart';

/// Pantalla de llista de xats (dades reals des de backend via [ChatsQuery]).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const Color _accentRed = AppThemeTokens.brandPrimary;

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

  bool _guardAuth() => guardAuthenticated(
    context,
    message: AppLocalizations.of(context).loginContinuePrompt,
    requireUserId: true,
  );

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
        _error = AppLocalizations.of(context).loadChatsFailed;
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
    await FeatureNavigation.openFriendConversation(context, chat: chat);
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
          SnackBar(
            content: Text(AppLocalizations.of(context).chatNotAvailableYet),
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
        SnackBar(content: Text(AppLocalizations.of(context).chatOpenFailed)),
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
        title: Text(
          AppLocalizations.of(context).chatsTitle,
          style: AppThemeTokens.appBarTitle,
        ),
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
              hintText: AppLocalizations.of(context).searchChatHint,
              margin: EdgeInsets.zero,
              suffixIcon: _searchController.text.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: AppLocalizations.of(context).deleteTooltip,
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
            actionLabel: AppLocalizations.of(context).retry,
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
            title: AppLocalizations.of(context).noChatsYet,
            subtitle: AppLocalizations.of(context).noChatsYetSubtitle,
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
            title: AppLocalizations.of(context).noChatsMatchSearch,
            subtitle: AppLocalizations.of(context).noChatsMatchSearchSubtitle,
            actionLabel: AppLocalizations.of(context).clearSearch,
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
