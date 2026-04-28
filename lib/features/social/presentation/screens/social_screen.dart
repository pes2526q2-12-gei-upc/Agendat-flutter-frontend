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
import 'package:agendat/features/social/presentation/screens/friend_requests_screen.dart';
import 'package:agendat/features/social/presentation/screens/friends_list_screen.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
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

  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardAuthenticated();
      _loadPendingRequestsCount();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

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

  /// Llegeix el nombre de sol·licituds rebudes pendents per mostrar un badge
  /// a l'icona d'accés a la pantalla de gestió de sol·licituds. Si falla, no
  /// mostra cap badge — la llista és accessible igualment.
  Future<void> _loadPendingRequestsCount({bool forceRefresh = false}) async {
    if (!_isAuthenticated) return;
    final myId = currentLoggedInUser?['id'];
    if (myId is! int) return;

    try {
      final data = await ProfileQuery.instance.getFriendRequests(
        myId,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      final pending = data.received
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
      setState(() => _pendingRequestsCount = pending);
    } catch (_) {
      // Silenciós: el badge és informatiu i no crític.
    }
  }

  Future<void> _openFriendRequests() async {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FriendRequestsScreen()));
    if (!mounted) return;
    // Refresquem el comptador en tornar perquè l'usuari pot haver acceptat o
    // rebutjat sol·licituds des de la pantalla.
    _loadPendingRequestsCount(forceRefresh: true);
  }

  Future<void> _openFriendsList() async {
    if (!_isAuthenticated) {
      _guardAuthenticated();
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FriendsListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Social',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            tooltip: 'Els meus amics',
            onPressed: _openFriendsList,
            icon: const Icon(Icons.group_outlined, color: Colors.black87),
          ),
          _FriendRequestsAction(
            pendingCount: _pendingRequestsCount,
            onPressed: _openFriendRequests,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppScreenSpacing.horizontal,
              8,
              AppScreenSpacing.horizontal,
              8,
            ),
            child: _buildSearchField(),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      onChanged: _onQueryChanged,
      decoration: InputDecoration(
        hintText: 'Cerca usuaris pel nom d\'usuari',
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Esborra',
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _kPrimaryRed, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) {
      return _buildCenteredMessage(
        icon: Icons.person_search,
        title: 'Cerca altres usuaris',
        subtitle: 'Escriu un nom d\'usuari per trobar i visitar el seu perfil.',
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
        4,
        AppScreenSpacing.horizontal,
        AppScreenSpacing.bottom,
      ),
      itemBuilder: (context, index) => _UserResultTile(
        user: _results[index],
        onTap: () => _openProfile(_results[index]),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
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

class _FriendRequestsAction extends StatelessWidget {
  const _FriendRequestsAction({
    required this.pendingCount,
    required this.onPressed,
  });

  final int pendingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasBadge = pendingCount > 0;
    final badgeLabel = pendingCount > 99 ? '99+' : '$pendingCount';

    return Tooltip(
      message: 'Sol·licituds d\'amistat',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: const Icon(
              Icons.person_add_alt_1_outlined,
              color: Colors.black87,
            ),
          ),
          if (hasBadge)
            Positioned(
              right: 6,
              top: 6,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
