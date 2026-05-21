import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/realtime/chat_realtime_service.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/core/widgets/require_auth.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/features/chat/presentation/widgets/chat_row.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/core/api/friendship_api.dart';
import 'package:agendat/features/social/presentation/screens/friends_list_screen.dart';
import 'package:agendat/core/state/pending_friend_requests_notifier.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/features/social/presentation/widgets/social_list_tiles.dart';
import 'package:agendat/core/state/root_tab_state.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  static const _kPrimaryRed = AppThemeTokens.brandPrimary;
  static const Duration _debounceDuration = Duration(milliseconds: 350);
  final ChatsQuery _chatsQuery = ChatsQuery.instance;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  StreamSubscription<ChatRealtimeEvent>? _realtimeSubscription;
  StreamSubscription<FriendshipChange>? _friendshipChangeSubscription;
  int _requestToken = 0;

  String _query = '';
  bool _isLoading = false;
  List<UserSummary> _results = const [];
  String? _errorMessage;

  bool _isLoadingRequests = false;
  String? _requestsErrorMessage;
  List<PendingFriendRequest> _pendingRequests = const [];
  final Set<int> _busyRequestIds = <int>{};
  bool _showPendingRequests = false;

  bool _isLoadingChats = false;
  String? _chatsErrorMessage;
  List<Chat> _chats = const [];

  bool _isLoadingRecommendations = false;
  String? _recommendationsErrorMessage;
  List<FriendRecommendation> _recommendations = const [];
  final Set<int> _busyRecommendationIds = <int>{};

  // Animació del pop-up del llistat d'amics. Es renderitza com a overlay
  // dins del cos de la pantalla i lliscà des de baix amb una animació
  // semblant a la d'un bottom sheet modal, però sense bloquejar la barra
  // de navegació arrel: així l'usuari pot canviar de pestanya i el pop-up
  // es tanca sol (vegeu [_onRootTabChanged]).
  late final AnimationController _popupController;
  late final Animation<Offset> _popupSlide;

  @override
  void initState() {
    super.initState();
    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _popupSlide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _popupController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
    _popupController.addStatusListener(_onPopupStatusChanged);
    rootTabIndexNotifier.addListener(_onRootTabChanged);
    _realtimeSubscription = ChatRealtimeService.instance.events.listen(
      _onRealtimeEvent,
    );
    _friendshipChangeSubscription = ProfileQuery.instance.friendshipChanges
        .listen(_onFriendshipChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardAuthenticated();
      _loadPendingRequestsCount();
      _loadFriendRecommendations();
      _loadChats();
    });
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _friendshipChangeSubscription?.cancel();
    rootTabIndexNotifier.removeListener(_onRootTabChanged);
    _popupController.removeStatusListener(_onPopupStatusChanged);
    _popupController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Tanca el pop-up del llistat d'amics quan l'usuari ha canviat a una
  /// altra pestanya: així no queda obert "ocult" al darrere de l'IndexedStack.
  void _onRootTabChanged() {
    if (rootTabIndexNotifier.value != kSocialTabIndex) {
      _closeFriendsPopup();
    } else if (_isAuthenticated) {
      final cached = _chatsQuery.peekCachedChatsList();
      if (cached != null) {
        setState(() => _chats = cached);
        syncUnreadChatConversationsBadge(cached);
      } else {
        _loadChats(forceRefresh: false);
      }
      _loadFriendRecommendations(forceRefresh: false);
    }
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

  void _onFriendshipChange(FriendshipChange change) {
    if (!mounted || !_isAuthenticated) return;
    unawaited(_refreshSocialFromCache());
  }

  void _syncChatsFromCache() {
    final cached = _chatsQuery.peekCachedChatsList();
    if (cached == null) return;
    setState(() => _chats = cached);
    syncUnreadChatConversationsBadge(cached);
  }

  /// Reconstrueix la jerarquia quan l'animació entra/surt dels seus extrems
  /// per afegir o treure el pop-up de l'arbre de widgets segons el seu
  /// estat (només es rendereix si està visible o animant-se).
  void _onPopupStatusChanged(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.dismissed ||
        status == AnimationStatus.completed) {
      setState(() {});
    }
  }

  bool get _isFriendsPopupVisible =>
      _popupController.status != AnimationStatus.dismissed;

  bool get _isAuthenticated => isAuthenticated();

  void _guardAuthenticated() {
    guardAuthenticated(
      context,
      message: 'Cal iniciar sessió per accedir al cercador d\'usuaris.',
    );
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _query = '';
        _results = const [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _query = trimmed;
      _isLoading = true;
      _errorMessage = null;
    });

    _debounce = Timer(_debounceDuration, () => _runSearch(trimmed));
  }

  Future<void> _runSearch(String query) async {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }

    final myToken = ++_requestToken;
    final result = await searchUsers(query);
    if (!mounted || myToken != _requestToken) return;

    switch (result) {
      case SearchUsersSuccess(:final users):
        final currentUserId = (currentLoggedInUser?['id'] as num?)?.toInt();
        final filtered = currentUserId == null
            ? users
            : users.where((u) => u.id != currentUserId).toList();
        setState(() {
          _results = filtered;
          _isLoading = false;
          _errorMessage = null;
        });
      case SearchUsersUnauthorized():
        _guardAuthenticated();
      case SearchUsersFailure(:final statusCode, :final error):
        setState(() {
          _isLoading = false;
          _results = const [];
          _errorMessage = error != null
              ? 'Error de connexió. Comprova la teva connexió a internet.'
              : 'Error del servidor (codi $statusCode).';
        });
    }
  }

  void _clearSearch() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _query = '';
      _results = const [];
      _isLoading = false;
      _errorMessage = null;
    });
    _focusNode.unfocus();
  }

  void _openProfile(UserSummary user) {
    unawaited(FeatureNavigation.openUserProfile(context, userId: user.id));
  }

  /// Llegeix les sol·licituds rebudes pendents per mostrar-les directament
  /// dins la pantalla social.
  Future<void> _loadPendingRequestsCount({bool forceRefresh = false}) async {
    if (!_isAuthenticated) return;
    final myId = currentLoggedInUser?['id'];
    if (myId is! int) return;

    setState(() {
      _isLoadingRequests = true;
      _requestsErrorMessage = null;
    });

    try {
      final data = await ProfileQuery.instance.getFriendRequests(
        myId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final pending = data.received
          .where((r) => r.status.toLowerCase() == 'pending')
          .toList();
      setState(() {
        _pendingRequests = pending;
        _isLoadingRequests = false;
      });
      syncPendingFriendRequestsBadge(pending.length);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRequests = false;
        _requestsErrorMessage =
            'No s\'han pogut carregar les sol·licituds. Comprova la teva connexió.';
      });
    }
  }

  Future<void> _refreshPendingRequestsFromCache() async {
    if (!_isAuthenticated) return;
    final myId = currentLoggedInUser?['id'];
    if (myId is! int) return;

    try {
      final data = await ProfileQuery.instance.getFriendRequests(myId);
      if (!mounted) return;
      final pending = data.received
          .where((r) => r.status.toLowerCase() == 'pending')
          .toList();
      setState(() {
        _pendingRequests = pending;
        _requestsErrorMessage = null;
      });
      syncPendingFriendRequestsBadge(pending.length);
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  UserSummary? _senderOf(PendingFriendRequest request) {
    return request.counterpart ?? request.requestedBy;
  }

  Future<void> _acceptRequest(PendingFriendRequest request) {
    return _runRequestAction(
      request: request,
      action: (userId) => acceptFriendRequest(userId),
      successMessage: 'Sol·licitud acceptada. Ara sou amics!',
      genericErrorMessage: 'No s\'ha pogut acceptar la sol·licitud.',
    );
  }

  Future<void> _rejectRequest(PendingFriendRequest request) {
    return _runRequestAction(
      request: request,
      action: (userId) => rejectFriendRequest(userId),
      successMessage: 'Sol·licitud rebutjada.',
      genericErrorMessage: 'No s\'ha pogut rebutjar la sol·licitud.',
    );
  }

  Future<void> _runRequestAction({
    required PendingFriendRequest request,
    required Future<FriendActionResult> Function(int userId) action,
    required String successMessage,
    required String genericErrorMessage,
  }) async {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }
    if (_busyRequestIds.contains(request.id)) return;

    final sender = _senderOf(request);
    if (sender == null) {
      _showSnack('Aquesta sol·licitud ja no és vàlida.');
      _removeRequest(request.id);
      return;
    }

    setState(() => _busyRequestIds.add(request.id));
    final result = await action(sender.id);

    if (!mounted) return;

    switch (result) {
      case FriendActionSuccess():
        setState(() {
          _busyRequestIds.remove(request.id);
          _pendingRequests = _pendingRequests
              .where((r) => r.id != request.id)
              .toList();
        });
        syncPendingFriendRequestsBadge(_pendingRequests.length);
        _invalidateCaches(targetUserId: sender.id);
        _showSnack(successMessage);
      case FriendActionUnauthorized():
        setState(() => _busyRequestIds.remove(request.id));
        _guardAuthenticated();
      case FriendActionUserNotFound():
        _removeRequest(request.id);
        _showSnack('Perfil no vàlid.');
        _invalidateCaches(targetUserId: sender.id);
      case FriendActionConflict(:final message):
        _removeRequest(request.id);
        _showSnack(message ?? 'Aquesta sol·licitud ja no és vàlida.');
        _invalidateCaches(targetUserId: sender.id);
      case FriendActionFailure(:final statusCode, :final error):
        setState(() => _busyRequestIds.remove(request.id));
        if (_isInvalidRequestStatus(statusCode)) {
          _removeRequest(request.id);
          _showSnack('Aquesta sol·licitud ja no és vàlida.');
          _invalidateCaches(targetUserId: sender.id);
          return;
        }
        final text = error != null && statusCode == -1
            ? 'Error de connexió. Comprova la teva connexió a internet.'
            : '$genericErrorMessage (codi $statusCode)';
        _showSnack(text);
    }
  }

  bool _isInvalidRequestStatus(int statusCode) {
    return statusCode == 400 ||
        statusCode == 404 ||
        statusCode == 409 ||
        statusCode == 410;
  }

  void _removeRequest(int requestId) {
    setState(() {
      _pendingRequests = _pendingRequests
          .where((r) => r.id != requestId)
          .toList();
      _busyRequestIds.remove(requestId);
    });
    syncPendingFriendRequestsBadge(_pendingRequests.length);
  }

  void _invalidateCaches({required int targetUserId}) {
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      ProfileQuery.instance.invalidateFriendshipLists(myId);
    }
    ProfileQuery.instance.invalidateUser(targetUserId);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message);
  }

  void _openFriendsList() {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }
    // Si ja està obert, l'icona actua com a tancament: així l'usuari pot
    // tornar a tocar la mateixa acció per fer-lo desaparèixer.
    if (_popupController.status == AnimationStatus.completed ||
        _popupController.status == AnimationStatus.forward) {
      _closeFriendsPopup();
      return;
    }
    setState(() {});
    _popupController.forward();
  }

  void _closeFriendsPopup() {
    if (_popupController.status == AnimationStatus.dismissed ||
        _popupController.status == AnimationStatus.reverse) {
      return;
    }
    _popupController.reverse();
  }

  Future<void> _loadChats({bool forceRefresh = false}) async {
    if (!_isAuthenticated) return;
    setState(() {
      _isLoadingChats = true;
      _chatsErrorMessage = null;
    });
    try {
      final chats = await _chatsQuery.getChats(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _isLoadingChats = false;
      });
      syncUnreadChatConversationsBadge(chats);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingChats = false;
        _chatsErrorMessage =
            'No s\'ha pogut carregar els xats. Comprova la teva connexió.';
      });
    }
  }

  Future<void> _refreshChatsFromCache() async {
    if (!_isAuthenticated) return;
    final cached = _chatsQuery.peekCachedChatsList();
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _chats = cached;
        _chatsErrorMessage = null;
      });
      syncUnreadChatConversationsBadge(cached);
      return;
    }

    try {
      final chats = await _chatsQuery.getChats();
      if (!mounted) return;
      setState(() {
        _chats = chats;
        _chatsErrorMessage = null;
      });
      syncUnreadChatConversationsBadge(chats);
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadFriendRecommendations({bool forceRefresh = false}) async {
    if (!_isAuthenticated) return;
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationsErrorMessage = null;
    });

    try {
      final data = await ProfileQuery.instance.getFriendRecommendations(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final currentUserId = (currentLoggedInUser?['id'] as num?)?.toInt();
      final blockedIds = ProfileQuery.instance.locallyBlockedUserIds;
      final recommendations = data.recommendations
          .where((r) => r.id != currentUserId && !blockedIds.contains(r.id))
          .toList();

      setState(() {
        _recommendations = recommendations;
        _isLoadingRecommendations = false;
        _recommendationsErrorMessage = null;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[social] friend recommendations load failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _isLoadingRecommendations = false;
        _recommendationsErrorMessage =
            'No s\'han pogut carregar les recomanacions.';
      });
    }
  }

  Future<void> _refreshFriendRecommendationsFromCache() async {
    if (!_isAuthenticated) return;

    try {
      final data = await ProfileQuery.instance.getFriendRecommendations();
      if (!mounted) return;

      final currentUserId = (currentLoggedInUser?['id'] as num?)?.toInt();
      final blockedIds = ProfileQuery.instance.locallyBlockedUserIds;
      final recommendations = data.recommendations
          .where((r) => r.id != currentUserId && !blockedIds.contains(r.id))
          .toList();

      setState(() {
        _recommendations = recommendations;
        _recommendationsErrorMessage = null;
      });
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  Future<void> _refreshSocialFromCache() async {
    await Future.wait([
      _refreshPendingRequestsFromCache(),
      _refreshFriendRecommendationsFromCache(),
      _refreshChatsFromCache(),
    ]);
  }

  Future<void> _refreshSocialOverview() async {
    await Future.wait([
      _loadPendingRequestsCount(forceRefresh: true),
      _loadFriendRecommendations(forceRefresh: true),
      _loadChats(forceRefresh: true),
    ]);
  }

  void _togglePendingRequestsView() {
    setState(() {
      _showPendingRequests = !_showPendingRequests;
    });
  }

  Future<void> _openChat(Chat chat) async {
    await FeatureNavigation.openFriendConversation(context, chat: chat);
    if (!mounted) return;
    await _loadChats(forceRefresh: true);
  }

  Future<void> _sendRecommendationRequest(FriendRecommendation rec) async {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }
    if (_busyRecommendationIds.contains(rec.id)) return;

    setState(() => _busyRecommendationIds.add(rec.id));
    final result = await sendFriendRequest(rec.id);

    if (!mounted) return;

    switch (result) {
      case FriendActionSuccess():
        setState(() {
          _busyRecommendationIds.remove(rec.id);
          _recommendations = _recommendations
              .where((candidate) => candidate.id != rec.id)
              .toList();
        });
        ProfileQuery.instance.recordFriendshipStatusChange(
          rec.id,
          FriendshipStatus.requestSent,
          otherSummary: rec.toUserSummary(),
        );
        final myId = currentLoggedInUser?['id'];
        if (myId is int) {
          ProfileQuery.instance.invalidateFriendRequestsList(myId);
        }
        ProfileQuery.instance.invalidateFriendRecommendations();
        _showSnack('Sol·licitud d\'amistat enviada.');
      case FriendActionUnauthorized():
        setState(() => _busyRecommendationIds.remove(rec.id));
        _guardAuthenticated();
      case FriendActionUserNotFound():
        _removeRecommendation(rec.id);
        ProfileQuery.instance.invalidateUser(rec.id);
        ProfileQuery.instance.invalidateFriendRecommendations();
        _showSnack('Perfil no vàlid.');
      case FriendActionConflict(:final message):
        _removeRecommendation(rec.id);
        ProfileQuery.instance.invalidateUser(rec.id);
        ProfileQuery.instance.invalidateFriendRecommendations();
        _showSnack(message ?? 'Aquesta recomanació ja no és vàlida.');
      case FriendActionFailure(:final statusCode, :final message, :final error):
        setState(() => _busyRecommendationIds.remove(rec.id));
        if (_isInvalidRequestStatus(statusCode)) {
          _removeRecommendation(rec.id);
          ProfileQuery.instance.invalidateUser(rec.id);
          ProfileQuery.instance.invalidateFriendRecommendations();
          _showSnack(message ?? 'Aquesta recomanació ja no és vàlida.');
          return;
        }
        final text =
            message ??
            (error != null && statusCode == -1
                ? 'Error de connexió. Comprova la teva connexió a internet.'
                : 'No s\'ha pogut enviar la sol·licitud.');
        _showSnack(text);
    }
  }

  void _removeRecommendation(int userId) {
    setState(() {
      _busyRecommendationIds.remove(userId);
      _recommendations = _recommendations
          .where((candidate) => candidate.id != userId)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: AppThemeTokens.screenBackground,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppScreenSpacing.horizontal,
                  AppScreenSpacing.top,
                  AppScreenSpacing.horizontal,
                  AppScreenSpacing.xs,
                ),
                child: _buildSearchField(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (_isFriendsPopupVisible)
            Positioned.fill(
              child: SlideTransition(
                position: _popupSlide,
                child: FriendsListScreen(
                  asPopup: true,
                  onClose: _closeFriendsPopup,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Capçalera de la pantalla Social.
  ///
  /// Substitueix l'`AppBar` del `Scaffold` perquè el pop-up del llistat
  /// d'amics pugui cobrir-la quan es desplega. Conserva el mateix aspecte
  /// (fons blanc, títol gran i accions a la dreta) sense perdre el padding
  /// del status bar.
  Widget _buildHeader() {
    return Material(
      color: AppThemeTokens.appBarBackground,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: AppThemeTokens.socialHeaderPadding,
          child: Row(
            children: [
              const Expanded(
                child: Text('Social', style: AppThemeTokens.appBarTitle),
              ),
              IconButton(
                tooltip: 'Actualitza',
                onPressed: _refreshSocialOverview,
                icon: const Icon(Icons.refresh, color: Colors.black87),
              ),
              IconButton(
                tooltip: 'Els meus amics',
                onPressed: _openFriendsList,
                icon: const Icon(Icons.group_outlined, color: Colors.black87),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return AppSearchBar(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onQueryChanged,
      textInputAction: TextInputAction.search,
      hintText: 'Cerca usuaris pel nom d\'usuari',
      margin: EdgeInsets.zero,
      suffixIcon: _query.isEmpty
          ? null
          : IconButton(
              tooltip: 'Esborra',
              icon: const Icon(Icons.close, color: Colors.black54),
              onPressed: _clearSearch,
            ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty && _showPendingRequests && _isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty &&
        _showPendingRequests &&
        _requestsErrorMessage != null) {
      return _buildCenteredMessage(
        icon: Icons.error_outline,
        title: _requestsErrorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => _loadPendingRequestsCount(forceRefresh: true),
      );
    }

    if (_query.isEmpty && _showPendingRequests && _pendingRequests.isNotEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppScreenSpacing.horizontal,
          AppScreenSpacing.xxs,
          AppScreenSpacing.horizontal,
          AppScreenSpacing.bottom,
        ),
        itemBuilder: (context, index) {
          final request = _pendingRequests[index];
          return SocialFriendRequestTile(
            request: request,
            isBusy: _busyRequestIds.contains(request.id),
            onAccept: () => _acceptRequest(request),
            onReject: () => _rejectRequest(request),
            onTap: () {
              final sender = _senderOf(request);
              if (sender != null) _openProfile(sender);
            },
          );
        },
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppScreenSpacing.xs),
        itemCount: _pendingRequests.length,
      );
    }

    if (_query.isEmpty) {
      if (_isLoadingChats && _chats.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_chatsErrorMessage != null && _chats.isEmpty) {
        return _buildCenteredMessage(
          icon: Icons.error_outline,
          title: _chatsErrorMessage!,
          actionLabel: 'Reintentar',
          onAction: () => _loadChats(forceRefresh: true),
        );
      }
      return RefreshIndicator(
        color: _kPrimaryRed,
        onRefresh: _refreshSocialOverview,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppScreenSpacing.horizontal,
            AppScreenSpacing.xxs,
            AppScreenSpacing.horizontal,
            AppScreenSpacing.bottom,
          ),
          children: [
            if (_pendingRequests.isNotEmpty) _buildPendingRequestsShortcut(),
            if (_pendingRequests.isNotEmpty)
              const SizedBox(height: AppScreenSpacing.xs),
            if (_shouldShowRecommendations) _buildRecommendationsShortcut(),
            if (_shouldShowRecommendations)
              const SizedBox(height: AppScreenSpacing.xs),
            if (_chats.isEmpty)
              _buildCenteredMessage(
                icon: Icons.chat_bubble_outline,
                title: 'Encara no tens cap conversa activa.',
              )
            else
              ..._chats.map(
                (chat) => Padding(
                  padding: const EdgeInsets.only(bottom: AppScreenSpacing.xs),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ChatRow(chat: chat, onTap: () => _openChat(chat)),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildCenteredMessage(
        icon: Icons.error_outline,
        title: _errorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => _runSearch(_query),
      );
    }

    if (_results.isEmpty) {
      return _buildCenteredMessage(
        icon: Icons.search_off,
        title: 'No s\'ha trobat cap usuari amb aquest nom.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppScreenSpacing.horizontal,
        AppScreenSpacing.xxs,
        AppScreenSpacing.horizontal,
        AppScreenSpacing.bottom,
      ),
      itemBuilder: (context, index) => SocialUserResultTile(
        user: _results[index],
        onTap: () => _openProfile(_results[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: AppScreenSpacing.xs),
      itemCount: _results.length,
    );
  }

  bool get _shouldShowRecommendations => _recommendations.isNotEmpty;

  Widget _buildRecommendationsShortcut() {
    if (_recommendations.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.people_outline, color: Colors.grey.shade500),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _recommendationsErrorMessage ??
                    'No hi ha recomanacions disponibles.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _loadFriendRecommendations(forceRefresh: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kPrimaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.people_outline, color: _kPrimaryRed),
        ),
        title: const Text(
          'Recomanacions d\'amics',
          style: TextStyle(fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _recommendations.length == 1
              ? '1 recomanació'
              : '${_recommendations.length} recomanacions',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isLoadingRecommendations
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: _openRecommendationsPopup,
      ),
    );
  }

  void _openRecommendationsPopup() {
    if (_recommendations.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final maxHeight = MediaQuery.of(context).size.height * 0.72;

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Persones que podries conèixer',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Tanca',
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final rec = _recommendations[index];
                            return SocialRecommendationTile(
                              recommendation: rec,
                              isBusy: _busyRecommendationIds.contains(rec.id),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _openProfile(rec.toUserSummary());
                              },
                              onAdd: () async {
                                final action = _sendRecommendationRequest(rec);
                                setSheetState(() {});
                                await action;
                                if (!mounted || !sheetContext.mounted) return;
                                if (_recommendations.isEmpty) {
                                  Navigator.of(sheetContext).pop();
                                } else {
                                  setSheetState(() {});
                                }
                              },
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemCount: _recommendations.length,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPendingRequestsShortcut() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _kPrimaryRed.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_add_alt_1, color: _kPrimaryRed),
        ),
        title: const Text(
          'Sol·licituds d\'amistat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${_pendingRequests.length} pendents per revisar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          _showPendingRequests ? Icons.expand_less : Icons.expand_more,
        ),
        onTap: _togglePendingRequestsView,
      ),
    );
  }

  Widget _buildCenteredMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
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
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
