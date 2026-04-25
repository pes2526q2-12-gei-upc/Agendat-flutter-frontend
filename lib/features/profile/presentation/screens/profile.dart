import 'package:flutter/material.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:agendat/features/profile/presentation/screens/settings_screen.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  /// Si és null, mostra el perfil de l'usuari actual.
  /// Si té un valor, mostra el perfil d'un altre usuari.
  final int? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _kPrimaryRed = Color(0xFFB71C1C);

  late TabController _tabController;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  UserProfile? _profile;
  UserStats? _stats;
  List<UserInterest> _interests = const [];
  List<UserSession> _sessions = const [];
  UserReviewsResponse? _reviewsResponse;
  String? _errorMessage;
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  FriendshipStatus? _friendshipStatus;
  bool _isFriendshipActionInProgress = false;

  bool get _isOwnProfile => widget.userId == null;

  int? get _currentUserId => currentLoggedInUser?['id'] as int?;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = widget.userId ?? currentLoggedInUser?['id'] as int?;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No s\'ha pogut obtenir l\'identificador de l\'usuari.';
      });
      return;
    }

    final result = await _profileQuery.getUserProfile(
      userId,
      forceRefresh: forceRefresh,
    );

    if (!mounted) return;

    switch (result) {
      case ProfileSuccess(:final profile):
        final stats = await _profileQuery
            .getUserStats(userId, forceRefresh: forceRefresh)
            .catchError((_) {
              return const UserStats(
                eventCount: 0,
                reviewCount: 0,
                reputation: 0,
              );
            });
        final interests = await _profileQuery
            .getUserInterests(userId, forceRefresh: forceRefresh)
            .catchError((_) {
              return const <UserInterest>[];
            });
        final reviewsResponse = await _profileQuery
            .getUserReviews(userId, forceRefresh: forceRefresh)
            .catchError((_) {
              return const UserReviewsResponse(count: 0, reviews: []);
            });
        final sessions = await _profileQuery
            .getUserSessions(
              username: profile.username,
              forceRefresh: forceRefresh,
            )
            .catchError((_) => const <UserSession>[]);

        final derivedStatus = await _resolveFriendshipStatus(
          profile: profile,
          forceRefresh: forceRefresh,
        );

        if (!mounted) return;

        setState(() {
          _profile = profile;
          _stats = stats;
          _interests = interests;
          _reviewsResponse = reviewsResponse;
          _sessions = sessions;
          _friendshipStatus = derivedStatus;
          _isLoading = false;
        });
      case ProfileNotFound():
        setState(() {
          _isLoading = false;
          _errorMessage = 'Perfil no trobat.';
        });
      case ProfileUnavailable():
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aquest perfil no està disponible.';
        });
      case ProfileFailure(:final statusCode, :final error):
        setState(() {
          _isLoading = false;
          _errorMessage = error != null
              ? 'Error de connexió. Comprova la teva connexió a internet.'
              : 'Error del servidor (codi $statusCode).';
        });
    }
  }

  Future<void> _requestLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirma'),
          content: const Text('Estàs segur/a que vols tancar la sessió?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tancar sessió'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    try {
      await logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut tancar la sessio.')),
      );
      setState(() => _isLoggingOut = false);
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Determina l'estat de la relació d'amistat entre l'usuari autenticat i
  /// l'usuari target.
  ///
  /// Com que la resposta actual de `GET /api/users/{id}/` no inclou cap camp
  /// que descrigui la relació amb l'usuari autenticat, derivem l'estat amb
  /// dues crides extra a `/friends/` i `/friend-requests/` de l'usuari actual.
  /// Això implica descarregar tota la llista d'amics i totes les pendents per
  /// comprovar un sol id: funciona, però escala O(N) amb el nombre d'amics.
  ///
  /// TODO(backend): quan el backend afegeixi un camp `friendship_status` a la
  /// resposta de `GET /api/users/{id}/` (valors: `none`, `request_sent`,
  /// `request_received`, `friends`, `blocked`), aquest mètode quedarà reduït
  /// a retornar `profile.friendshipStatus` i podrem eliminar les crides extra.
  /// El mapeig ja està llest a `friendshipStatusFromString` (user_profile.dart).
  Future<FriendshipStatus?> _resolveFriendshipStatus({
    required UserProfile profile,
    required bool forceRefresh,
  }) async {
    if (_isOwnProfile) return null;
    if (profile.friendshipStatus != null) return profile.friendshipStatus;

    final myId = _currentUserId;
    if (myId == null || myId == profile.id) {
      debugPrint(
        '[profile] skip friendship derivation (myId=$myId, targetId=${profile.id})',
      );
      return null;
    }

    final friendsFuture = _profileQuery
        .getFriends(myId, forceRefresh: forceRefresh)
        .catchError((error) {
          debugPrint('[profile] getFriends($myId) failed: $error');
          return const <UserSummary>[];
        });
    final requestsFuture = _profileQuery
        .getFriendRequests(myId, forceRefresh: forceRefresh)
        .catchError((error) {
          debugPrint('[profile] getFriendRequests($myId) failed: $error');
          return FriendRequestsData.empty;
        });

    final friends = await friendsFuture;
    if (friends.any((u) => u.id == profile.id)) {
      debugPrint('[profile] target ${profile.id} is a friend of $myId');
      return FriendshipStatus.friends;
    }

    final requests = await requestsFuture;

    // `counterpart` és l'altre usuari (destinatari a `sent`, remitent a
    // `received`). Comprovem també `requested_by` / `blocked_by` per si algun
    // dia el backend canvia la serialització.
    bool involves(PendingFriendRequest request) {
      final counterpart = request.counterpart;
      if (counterpart != null) {
        if (counterpart.id == profile.id) return true;
        if (counterpart.username == profile.username) return true;
      }

      final requestedBy = request.requestedBy;
      if (requestedBy != null && requestedBy.id == profile.id) {
        return true;
      }

      final blockedBy = request.blockedBy;
      if (blockedBy != null && blockedBy.id == profile.id) {
        return true;
      }

      return false;
    }

    final sentMatch = requests.sent.any(involves);
    final receivedMatch = !sentMatch && requests.received.any(involves);

    debugPrint(
      '[profile] derived friendship with ${profile.id}: '
      'friends=${friends.length}, sent=${requests.sent.length}, '
      'received=${requests.received.length}, '
      'sentMatch=$sentMatch, receivedMatch=$receivedMatch',
    );

    if (sentMatch) return FriendshipStatus.requestSent;
    if (receivedMatch) return FriendshipStatus.requestReceived;
    return FriendshipStatus.none;
  }

  Future<void> _runFriendshipAction({
    required Future<FriendActionResult> Function() action,
    required FriendshipStatus successStatus,
    required String successMessage,
    required String genericErrorMessage,
  }) async {
    if (_isFriendshipActionInProgress) return;

    setState(() => _isFriendshipActionInProgress = true);

    final result = await action();

    if (!mounted) return;

    switch (result) {
      case FriendActionSuccess():
        setState(() {
          _friendshipStatus = successStatus;
          if (_profile != null) {
            _profile = _profile!.copyWithFriendshipStatus(successStatus);
          }
          _isFriendshipActionInProgress = false;
        });
        // Actualitzem la caché del QueryClient per mantenir l'estat entre
        // navegacions, fins que expiri el staleTime o el backend el refresqui.
        final otherId = widget.userId;
        if (otherId != null) {
          _profileQuery.setCachedFriendshipStatus(otherId, successStatus);
        }
        // Invalidem també les llistes d'amistat del meu usuari: així, si
        // tanco l'app o recarrego la pantalla, la pròxima derivació consultarà
        // el backend i l'estat del botó serà coherent amb la veritat.
        final myId = _currentUserId;
        if (myId != null) {
          _profileQuery.invalidateFriendshipLists(myId);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      case FriendActionUnauthorized():
        setState(() => _isFriendshipActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cal iniciar sessió per fer aquesta acció.'),
          ),
        );
      case FriendActionFailure(:final statusCode, :final message, :final error):
        setState(() => _isFriendshipActionInProgress = false);
        final text =
            message ??
            (error != null && statusCode == -1
                ? 'Error de connexió. Comprova la teva connexió a internet.'
                : genericErrorMessage);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _sendFriendRequest() {
    final userId = widget.userId;
    if (userId == null) return Future.value();
    return _runFriendshipAction(
      action: () => sendFriendRequest(userId),
      successStatus: FriendshipStatus.requestSent,
      successMessage: 'Sol·licitud d\'amistat enviada.',
      genericErrorMessage: 'No s\'ha pogut enviar la sol·licitud.',
    );
  }

  Future<void> _cancelFriendRequest() {
    final userId = widget.userId;
    if (userId == null) return Future.value();
    return _runFriendshipAction(
      action: () => cancelFriendRequest(userId),
      successStatus: FriendshipStatus.none,
      successMessage: 'Sol·licitud d\'amistat cancel·lada.',
      genericErrorMessage: 'No s\'ha pogut cancel·lar la sol·licitud.',
    );
  }

  Future<void> _acceptFriendRequest() {
    final userId = widget.userId;
    if (userId == null) return Future.value();
    return _runFriendshipAction(
      action: () => acceptFriendRequest(userId),
      successStatus: FriendshipStatus.friends,
      successMessage: 'Sol·licitud acceptada. Ara sou amics!',
      genericErrorMessage: 'No s\'ha pogut acceptar la sol·licitud.',
    );
  }

  Future<void> _rejectFriendRequest() {
    final userId = widget.userId;
    if (userId == null) return Future.value();
    return _runFriendshipAction(
      action: () => rejectFriendRequest(userId),
      successStatus: FriendshipStatus.none,
      successMessage: 'Sol·licitud rebutjada.',
      genericErrorMessage: 'No s\'ha pogut rebutjar la sol·licitud.',
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (_profile == null) return;

    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: _profile!),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
      await setCurrentLoggedInUser({
        ...currentLoggedInUser ?? {},
        'id': updatedProfile.id,
        'username': updatedProfile.username,
        'email': updatedProfile.email,
        'first_name': updatedProfile.firstName,
        'last_name': updatedProfile.lastName,
        'description': updatedProfile.description,
        'profile_image': updatedProfile.profileImage,
        'notifications_allowed': updatedProfile.notificationsAllowed,
        'event_reminders_allowed': updatedProfile.eventRemindersAllowed,
        'event_updates_allowed': updatedProfile.eventUpdatesAllowed,
        'social_alerts_allowed': updatedProfile.socialAlertsAllowed,
      });
    }
  }

  Future<void> _navigateToNotificationPreferences() async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cal iniciar sessió per configurar alertes.'),
        ),
      );
      return;
    }

    if (_profile == null) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(currentProfile: _profile!),
      ),
    );

    if (mounted) {
      await _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isOwnProfile ? 'El meu Perfil' : 'Perfil',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: !_isOwnProfile,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: _isOwnProfile
          ? [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black54,
                ),
                onPressed: _navigateToNotificationPreferences,
              ),
            ]
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadProfile(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    return RefreshIndicator(
      onRefresh: () => _loadProfile(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(profile),
            const SizedBox(height: 16),
            _buildInterestsSection(_interests),
            const SizedBox(height: 16),
            _buildTabSection(
              attendedSessions: _sessions,
              reviewsResponse: _reviewsResponse,
            ),
            if (_isOwnProfile) ...[
              const SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(profile),
              const SizedBox(width: 16),
              Expanded(child: _buildProfileInfo(profile)),
              if (_isOwnProfile)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                  onPressed: _navigateToEditProfile,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsRow(_stats),
          if (!_isOwnProfile) ...[
            const SizedBox(height: 16),
            _buildFriendshipSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendshipSection() {
    if (_currentUserId == null || widget.userId == _currentUserId) {
      return const SizedBox.shrink();
    }

    final status = _friendshipStatus ?? FriendshipStatus.none;
    final busy = _isFriendshipActionInProgress;

    switch (status) {
      case FriendshipStatus.none:
        return _buildFriendshipPrimaryButton(
          onPressed: busy ? null : _sendFriendRequest,
          icon: Icons.person_add_alt_1,
          label: 'Enviar sol·licitud d\'amistat',
          busy: busy,
        );
      case FriendshipStatus.requestSent:
        return _buildFriendshipOutlinedButton(
          onPressed: busy ? null : _cancelFriendRequest,
          icon: Icons.hourglass_top,
          label: 'Sol·licitud enviada · Cancel·lar',
          busy: busy,
        );
      case FriendshipStatus.requestReceived:
        return Row(
          children: [
            Expanded(
              child: _buildFriendshipPrimaryButton(
                onPressed: busy ? null : _acceptFriendRequest,
                icon: Icons.check,
                label: 'Acceptar',
                busy: busy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFriendshipOutlinedButton(
                onPressed: busy ? null : _rejectFriendRequest,
                icon: Icons.close,
                label: 'Rebutjar',
                busy: false,
              ),
            ),
          ],
        );
      case FriendshipStatus.friends:
        return _buildFriendshipBadge(
          icon: Icons.check_circle,
          text: 'Ja sou amics',
          background: Colors.green.shade50,
          borderColor: Colors.green.shade200,
          iconColor: Colors.green.shade700,
          textColor: Colors.green.shade800,
        );
      case FriendshipStatus.blocked:
        return _buildFriendshipBadge(
          icon: Icons.block,
          text: 'Usuari bloquejat',
          background: Colors.grey.shade100,
          borderColor: Colors.grey.shade300,
          iconColor: Colors.grey.shade700,
          textColor: Colors.grey.shade800,
        );
    }
  }

  Widget _buildFriendshipBadge({
    required IconData icon,
    required String text,
    required Color background,
    required Color borderColor,
    required Color iconColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendshipPrimaryButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool busy,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimaryRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kPrimaryRed.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendshipOutlinedButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool busy,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryRed,
          side: const BorderSide(color: _kPrimaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    final imageUrl = resolveProfileImageUrl(profile.profileImage);
    const radius = 45.0;
    const size = radius * 2;

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
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
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildRatingBadge(_stats?.reputation),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                profile.displayDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBadge(double? reputation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            reputation == null ? '—' : reputation.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserStats? stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('${stats?.eventCount ?? 0}', 'Esdeveniments'),
        _buildStatItem('${stats?.reviewCount ?? 0}', 'Valoracions'),
        _buildStatItem(
          stats == null ? '—' : stats.reputation.toStringAsFixed(1),
          'Reputació',
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _kPrimaryRed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(List<UserInterest> interests) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOwnProfile ? 'Els meus interessos' : 'Interessos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isOwnProfile)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Editar interessos pendent'),
                      ),
                    );
                  },
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text(
              'Cap interès afegit',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map(
                    (i) => Chip(
                      label: Text(i.name),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSection({
    required List<UserSession> attendedSessions,
    required UserReviewsResponse? reviewsResponse,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: _kPrimaryRed,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: _kPrimaryRed,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              const Tab(text: 'Assistits'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ressenyes'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${reviewsResponse?.count ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendedSessionsTab(attendedSessions),
                _buildReviewsTab(reviewsResponse),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedSessionsTab(List<UserSession> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyTabContent(
        'No hi ha esdeveniments',
        Icons.event_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final s = sessions[index];
        final start = s.startTime;
        final startLabel =
            '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.event, color: Colors.grey.shade600),
          title: Text(
            s.eventCode.isEmpty ? 'Event' : s.eventCode,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(startLabel),
        );
      },
    );
  }

  Widget _buildReviewsTab(UserReviewsResponse? response) {
    final reviews = response?.reviews ?? const <UserReview>[];
    if (reviews.isEmpty) {
      return _buildEmptyTabContent(
        'No hi ha ressenyes',
        Icons.rate_review_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final r = reviews[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.rate_review, color: Colors.grey.shade600),
          title: Text(
            r.reviewerUsername.isEmpty ? 'Usuari' : r.reviewerUsername,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(r.comment.isEmpty ? '—' : r.comment),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '${r.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabContent(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _isLoggingOut ? null : _requestLogOut,
        icon: _isLoggingOut
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_outlined),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryRed,
          side: const BorderSide(color: _kPrimaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        label: const Text(
          'Tancar sessió',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
