import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Pantalla que llista els amics de l'usuari autenticat.
///
/// Es nodreix de `GET /api/users/{id}/friends/` (a través de `ProfileQuery`).
/// Per definició aquest endpoint només retorna relacions d'amistat actives
/// (acceptades), de manera que els usuaris bloquejats no apareixen aquí: el
/// bloqueig al backend implica que la relació d'amistat ja no existeix.
class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key, this.asPopup = false, this.onClose});

  final bool asPopup;

  /// Callback opcional invocat quan l'usuari sol·licita tancar la vista en
  /// mode popup. Si no es proporciona, s'intenta un `Navigator.maybePop`
  /// (per quan la pantalla es mostra com a ruta normal).
  final VoidCallback? onClose;

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  static const _kPrimaryRed = Color(0xFFB71C1C);

  final ProfileQuery _profileQuery = ProfileQuery.instance;
  final TextEditingController _filterController = TextEditingController();
  final FocusNode _filterFocusNode = FocusNode();

  bool _isLoading = true;
  String? _errorMessage;
  List<UserSummary> _friends = const [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuthenticated()) return;
      _loadFriends();
    });
  }

  @override
  void dispose() {
    _filterController.dispose();
    _filterFocusNode.dispose();
    super.dispose();
  }

  bool get _isAuthenticated =>
      currentAuthToken != null &&
      currentAuthToken!.trim().isNotEmpty &&
      currentLoggedInUser?['id'] is int;

  /// Si la sessió no és vàlida, mostra un snackbar i redirigeix al login.
  /// Retorna `true` si l'usuari està autenticat.
  bool _guardAuthenticated() {
    if (_isAuthenticated || !mounted) return _isAuthenticated;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cal iniciar sessió per veure el teu llistat d\'amics.'),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return false;
  }

  Future<void> _loadFriends({bool forceRefresh = false}) async {
    if (!_guardAuthenticated()) return;

    final myId = currentLoggedInUser!['id'] as int;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final friends = await _profileQuery.getFriends(
        myId,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _friends = _sortAlphabetically(friends);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[friends-list] load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No s\'ha pogut carregar el llistat d\'amics. Comprova la teva connexió.';
      });
    }
  }

  /// Ordenació alfabètica per `displayName` (cau a `username` si no hi ha
  /// nom). Fa servir comparació case-insensitive perquè la barreja de
  /// majúscules/minúscules no afecti l'ordre percebut.
  List<UserSummary> _sortAlphabetically(List<UserSummary> users) {
    final sorted = [...users];
    sorted.sort((a, b) {
      final aKey = a.displayName.toLowerCase();
      final bKey = b.displayName.toLowerCase();
      final byName = aKey.compareTo(bKey);
      if (byName != 0) return byName;
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return sorted;
  }

  /// Amics actius: tot el que ve del backend menys els usuaris que la sessió
  /// actual ja sap que no han d'aparèixer (`blocked` o `unfriended`).
  /// Garanteix que un usuari acabat de bloquejar o d'eliminar com a amic
  /// desapareixi a l'instant, encara que `getFriends` encara retorni la
  /// versió antiga des de la caché.
  List<UserSummary> get _unblockedFriends {
    final blockedIds = _profileQuery.locallyBlockedUserIds;
    final unfriendedIds = _profileQuery.locallyUnfriendedUserIds;
    if (blockedIds.isEmpty && unfriendedIds.isEmpty) return _friends;
    return _friends
        .where(
          (u) => !blockedIds.contains(u.id) && !unfriendedIds.contains(u.id),
        )
        .toList();
  }

  /// Llistat finalment visible: amics actius + filtre de text si està actiu.
  List<UserSummary> get _visibleFriends {
    final unblocked = _unblockedFriends;
    if (_filter.isEmpty) return unblocked;
    final lowered = _filter.toLowerCase();
    return unblocked.where((u) {
      return u.username.toLowerCase().contains(lowered) ||
          u.displayName.toLowerCase().contains(lowered);
    }).toList();
  }

  void _onFilterChanged(String value) {
    setState(() => _filter = value.trim());
  }

  void _clearFilter() {
    _filterController.clear();
    _filterFocusNode.unfocus();
    setState(() => _filter = '');
  }

  Future<void> _openProfile(UserSummary user) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)));
    if (!mounted) return;

    // En tornar del perfil, l'estat local pot haver canviat (bloqueig,
    // desbloqueig o amistat eliminada). Forcem una reconstrucció perquè
    // `_visibleFriends` reapliqui els filtres locals sense haver de refetchar
    // de xarxa ni mostrar un spinner.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return widget.asPopup
          ? const SizedBox.shrink()
          : const Scaffold(body: SizedBox.shrink());
    }

    final content = Column(
      children: [
        if (!_isLoading &&
            _errorMessage == null &&
            _unblockedFriends.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppScreenSpacing.horizontal,
              8,
              AppScreenSpacing.horizontal,
              4,
            ),
            child: _buildFilterField(),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadFriends(forceRefresh: true),
            child: _buildBody(),
          ),
        ),
      ],
    );

    if (widget.asPopup) {
      return Material(
        color: Colors.grey.shade50,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppScreenSpacing.horizontal,
                  12,
                  10,
                  8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Els meus amics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tanca',
                      onPressed: () {
                        if (widget.onClose != null) {
                          widget.onClose!();
                        } else {
                          Navigator.of(context).maybePop();
                        }
                      },
                      icon: const Icon(Icons.close, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Els meus amics',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: content,
    );
  }

  Widget _buildFilterField() {
    return TextField(
      controller: _filterController,
      focusNode: _filterFocusNode,
      onChanged: _onFilterChanged,
      decoration: InputDecoration(
        hintText: 'Filtra els teus amics',
        prefixIcon: const Icon(Icons.search, color: Colors.black54),
        suffixIcon: _filter.isEmpty
            ? null
            : IconButton(
                tooltip: 'Esborra',
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: _clearFilter,
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _buildCenteredMessage(
            icon: Icons.error_outline,
            title: _errorMessage!,
            actionLabel: 'Reintentar',
            onAction: () => _loadFriends(forceRefresh: true),
          ),
        ],
      );
    }

    // Considerem la llista buida si no hi ha cap amic actiu (ja descomptats
    // els bloquejats localment): així si l'únic amic que tenia ha estat
    // bloquejat, mostrem el missatge buit en comptes de "Cap amic coincideix
    // amb el filtre".
    if (_unblockedFriends.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _buildCenteredMessage(
            icon: Icons.group_outlined,
            title: 'Encara no tens cap amic a la teva xarxa.',
            subtitle:
                'Cerca usuaris i envia\'ls una sol·licitud per ampliar la teva xarxa.',
          ),
        ],
      );
    }

    final visible = _visibleFriends;
    if (visible.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _buildCenteredMessage(
            icon: Icons.search_off,
            title: 'Cap amic coincideix amb el filtre.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppScreenSpacing.horizontal,
        8,
        AppScreenSpacing.horizontal,
        AppScreenSpacing.bottom,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final friend = visible[index];
        return _FriendTile(user: friend, onTap: () => _openProfile(friend));
      },
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

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.user, required this.onTap});

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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    const size = radius * 2;
    final imageUrl = resolveProfileImageUrl(profileImage);

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 26, color: Colors.grey.shade400),
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
            child: Icon(Icons.person, size: 26, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
