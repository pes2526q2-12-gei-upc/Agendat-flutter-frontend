import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';
import 'package:agendat/features/social/presentation/screens/friends_list_screen.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/main.dart' show rootTabIndexNotifier, kSocialTabIndex;

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  static const _kPrimaryRed = Color(0xFFB71C1C);
  static const Duration _debounceDuration = Duration(milliseconds: 350);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  int _requestToken = 0;

  String _query = '';
  bool _isLoading = false;
  List<UserSummary> _results = const [];
  String? _errorMessage;

  bool _isLoadingRequests = false;
  String? _requestsErrorMessage;
  List<PendingFriendRequest> _pendingRequests = const [];
  final Set<int> _busyRequestIds = <int>{};

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardAuthenticated();
      _loadPendingRequestsCount();
    });
  }

  @override
  void dispose() {
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
    }
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

  bool get _isAuthenticated =>
      currentAuthToken != null && currentAuthToken!.trim().isNotEmpty;

  void _guardAuthenticated() {
    if (_isAuthenticated || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cal iniciar sessió per accedir al cercador d\'usuaris.'),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)));
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingRequests = false;
        _requestsErrorMessage =
            'No s\'han pogut carregar les sol·licituds. Comprova la teva connexió.';
      });
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (_query.isEmpty && _isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_query.isEmpty && _requestsErrorMessage != null) {
      return _buildCenteredMessage(
        icon: Icons.error_outline,
        title: _requestsErrorMessage!,
        actionLabel: 'Reintentar',
        onAction: () => _loadPendingRequestsCount(forceRefresh: true),
      );
    }

    if (_query.isEmpty && _pendingRequests.isNotEmpty) {
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
          return _FriendRequestTile(
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
      return _buildCenteredMessage(
        icon: Icons.inbox_outlined,
        title: 'Encara no tens cap conversa activa.',
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
      itemBuilder: (context, index) => _UserResultTile(
        user: _results[index],
        onTap: () => _openProfile(_results[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: AppScreenSpacing.xs),
      itemCount: _results.length,
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

class _UserResultTile extends StatelessWidget {
  const _UserResultTile({required this.user, required this.onTap});

  final UserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
              _Avatar(profileImage: user.profileImage),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  static const _kPrimaryRed = Color(0xFFB71C1C);

  final PendingFriendRequest request;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sender = request.counterpart ?? request.requestedBy;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: sender == null ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(profileImage: sender?.profileImage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender?.displayName ?? 'Usuari desconegut',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sender != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${sender.username}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (request.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(request.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : onAccept,
                        icon: isBusy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Acceptar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _kPrimaryRed.withValues(
                            alpha: 0.6,
                          ),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Rebutjar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryRed,
                          side: const BorderSide(color: _kPrimaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $hh:$mm';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    const size = radius * 2;
    final imageUrl = resolveProfileImageUrl(profileImage);

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 28, color: Colors.grey.shade400),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Icon(Icons.person, size: 28, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
