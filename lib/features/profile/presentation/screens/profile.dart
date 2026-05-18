import 'package:flutter/material.dart';
import 'package:agendat/core/dto/category_dto.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/query/categories_query.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:agendat/features/profile/presentation/screens/edit_interests_screen.dart';
import 'package:agendat/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:agendat/features/profile/presentation/screens/settings_screen.dart';
import 'package:agendat/features/social/data/social_api.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_attended_sessions_tab.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_friendship_section.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_interests_section.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_reviews_tab.dart';
import 'package:agendat/features/profile/presentation/widgets/profile_summary_card.dart';

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
  late TabController _tabController;
  bool _isLoading = true;
  bool _isLoggingOut = false;
  UserProfile? _profile;
  UserStats? _stats;
  int? _attendanceCount;
  int? _reviewsCount;
  List<UserInterest> _interests = const [];
  UserReviewsResponse? _reviewsResponse;
  String? _errorMessage;
  final ProfileQuery _profileQuery = ProfileQuery.instance;
  final CategoriesQuery _categoriesQuery = CategoriesQuery.instance;
  final SessionsQuery _sessionsQuery = SessionsQuery.instance;
  final EventsQuery _eventsQuery = EventsQuery.instance;

  FriendshipStatus? _friendshipStatus;
  bool _isFriendshipActionInProgress = false;
  bool _isBlockActionInProgress = false;

  bool get _isOwnProfile => widget.userId == null;

  int? get _currentUserId {
    final raw = currentLoggedInUser?['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Quan visitem el perfil d'un altre usuari forcem un refetch: el seu
    // `friendship_status` pot haver canviat sense que en rebéssim cap
    // notificació (per exemple, l'altre ens ha eliminat com a amic, o ha
    // acceptat la nostra sol·licitud). Així `_applyBackendFriendshipState`
    // a `ProfileQuery` resincronitza també la nostra llista d'amics
    // cachejada. Per al perfil propi mantenim el comportament cachejat:
    // les nostres pròpies dades ja s'actualitzen via mutacions locals i no
    // val la pena pagar un fetch cada cop que canviem de pestanya.
    _loadProfile(forceRefresh: widget.userId != null);
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

    final userId = widget.userId ?? _currentUserId;
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
        final refreshDerived = forceRefresh || _isOwnProfile;
        final statsFuture = _loadUserStatsSafe(
          userId,
          forceRefresh: refreshDerived,
        );
        final interestsFuture = _profileQuery
            .getUserInterests(userId, forceRefresh: refreshDerived)
            .catchError((_) => const <UserInterest>[]);
        final categoriesFuture = _categoriesQuery.getCategoryDtos().catchError(
          (_) => const <CategoryDto>[],
        );
        final reviewsFuture = _profileQuery
            .getUserReviews(userId, forceRefresh: refreshDerived)
            .catchError(
              (_) => const UserReviewsResponse(count: 0, reviews: []),
            );
        final sessionsFuture = _isOwnProfile
            ? _sessionsQuery
                  .getSessions(forceRefresh: refreshDerived)
                  .catchError((_) => const <Session>[])
            : Future<List<Session>>.value(const []);

        final results = await Future.wait([
          statsFuture,
          interestsFuture,
          categoriesFuture,
          reviewsFuture,
          sessionsFuture,
        ]);

        final stats = results[0] as UserStats?;
        final interests = _withCategoryEmojis(
          results[1] as List<UserInterest>,
          results[2] as List<CategoryDto>,
        );
        final reviewsResponse = results[3] as UserReviewsResponse;
        final sessions = results[4] as List<Session>;

        final attendanceCount = _isOwnProfile
            ? sessions.length
            : stats?.eventCount;
        final reviewsCount = reviewsResponse.count;

        final derivedStatus = _resolveFriendshipStatus(profile: profile);

        if (!mounted) return;

        setState(() {
          _profile = profile;
          _stats = stats;
          _attendanceCount = attendanceCount;
          _reviewsCount = reviewsCount;
          _interests = interests;
          _reviewsResponse = reviewsResponse;
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

  Future<UserStats?> _loadUserStatsSafe(
    int userId, {
    required bool forceRefresh,
  }) async {
    try {
      return await _profileQuery.getUserStats(
        userId,
        forceRefresh: forceRefresh,
      );
    } catch (_) {
      return null;
    }
  }

  List<UserInterest> _withCategoryEmojis(
    List<UserInterest> interests,
    List<CategoryDto> categories,
  ) {
    if (interests.isEmpty || categories.isEmpty) return interests;

    final emojiById = <int, String>{};
    for (final category in categories) {
      final id = category.id;
      final emoji = category.emoji;
      if (id != null && emoji != null && emoji.isNotEmpty) {
        emojiById[id] = emoji;
      }
    }
    if (emojiById.isEmpty) return interests;

    return interests.map((interest) {
      if (interest.emoji != null && interest.emoji!.isNotEmpty) {
        return interest;
      }
      final emoji = emojiById[interest.id];
      return emoji == null ? interest : interest.copyWith(emoji: emoji);
    }).toList();
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
              child: const Text('Cancel·lar'),
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
        const SnackBar(content: Text('No s\'ha pogut tancar la sessió.')),
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

  /// Determina l'estat de relació amb el perfil visualitzat.
  ///
  /// Ara que el backend ja retorna `friendship_status` dins de
  /// `GET /api/users/{id}/`, aquesta font és la veritat principal i ja no cal
  /// derivar l'estat descarregant `/friends/` i `/friend-requests/`.
  ///
  /// Mantenim un fallback local a `blocked` per donar resposta immediata just
  /// després d'una acció optimista de bloqueig, fins i tot abans del següent
  /// refetch de perfil.
  FriendshipStatus? _resolveFriendshipStatus({required UserProfile profile}) {
    if (_isOwnProfile) return null;

    final myId = _currentUserId;
    if (myId == null || myId == profile.id) {
      return null;
    }

    final isBlockedLocally = _profileQuery.isUserLocallyBlocked(profile.id);
    if (isBlockedLocally) return FriendshipStatus.blocked;
    return profile.friendshipStatus ?? FriendshipStatus.none;
  }

  Future<void> _runFriendshipAction({
    required Future<FriendActionResult> Function() action,
    required FriendshipStatus successStatus,
    required String successMessage,
    required String genericErrorMessage,
    String unauthorizedMessage = 'Cal iniciar sessió per fer aquesta acció.',
    String notFoundMessage = 'Perfil no vàlid.',
    String invalidActionMessage =
        'Aquesta acció no és vàlida perquè actualment no sou amics.',
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
          _profileQuery.recordFriendshipStatusChange(
            otherId,
            successStatus,
            otherSummary: _profile?.toSummary(),
          );
        }
        // La llista de sol·licituds (sent/received) sí que cal forçar-la a
        // refetchar: l'optimisme local només pot afegir/treure un sol amic,
        // no mantenir el flux complet de sol·licituds coherent.
        final myId = _currentUserId;
        if (myId != null) {
          _profileQuery.invalidateFriendRequestsList(myId);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
      case FriendActionUnauthorized():
        setState(() => _isFriendshipActionInProgress = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(unauthorizedMessage)));
      case FriendActionUserNotFound():
        setState(() => _isFriendshipActionInProgress = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(notFoundMessage)));
      case FriendActionConflict(:final message):
        setState(() => _isFriendshipActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message ?? invalidActionMessage)),
        );
        // El backend ens diu que la nostra premissa local sobre l'estat
        // d'amistat és incorrecta (p. ex. provem de cancel·lar una
        // sol·licitud que ja s'ha acceptat, o d'enviar-ne una a algú que ja
        // és amic nostre). Recarreguem el perfil amb força per recuperar el
        // `friendship_status` real i actualitzar la UI sense haver d'esperar
        // que la caché es marqui com a obsoleta.
        _resyncProfileWithBackend();
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
        // Codis 400/410 en una mutació d'amistat solen voler dir el mateix
        // que el 409: estat incoherent. Ho tractem igual i resincronitzem.
        if (statusCode == 400 || statusCode == 410) {
          _resyncProfileWithBackend();
        }
    }
  }

  /// Recarrega el perfil saltant-se la caché. La crida posterior a
  /// `getUserProfile` farà servir `friendship_status` retornat pel backend
  /// com a font de veritat: actualitzarà la UI, els conjunts locals i la
  /// llista d'amics cachejada (a través de `_applyBackendFriendshipState` a
  /// `ProfileQuery`).
  void _resyncProfileWithBackend() {
    if (!mounted) return;
    _loadProfile(forceRefresh: true);
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

  Future<void> _confirmAndUnfriendUser() async {
    final profile = _profile;
    if (profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar amistat'),
          content: Text(
            'Vols eliminar @${profile.username} de la teva xarxa d\'amics? '
            'Deixareu de tenir un vincle directe i, si voleu, podreu '
            'tornar-vos a enviar una sol·licitud d\'amistat en el futur.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar amistat'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await _unfriendUser();
  }

  Future<void> _unfriendUser() {
    final userId = widget.userId;
    if (userId == null) return Future.value();
    return _runFriendshipAction(
      action: () => unfriendUser(userId),
      successStatus: FriendshipStatus.none,
      successMessage: 'Amistat eliminada.',
      genericErrorMessage: 'No s\'ha pogut eliminar l\'amistat.',
      unauthorizedMessage: 'Cal iniciar sessió per eliminar amistats.',
      notFoundMessage: 'Perfil no vàlid.',
      invalidActionMessage:
          'Aquesta acció no és vàlida perquè actualment no sou amics.',
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
        'calendar_sync_allowed': updatedProfile.calendarSyncAllowed,
      });
    }
  }

  Future<void> _navigateToEditInterests() async {
    final profile = _profile;
    if (profile == null) return;
    final userId = _isOwnProfile ? _currentUserId : profile.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No s\'ha pogut obrir l\'editor d\'interessos. Torna a iniciar sessió.',
          ),
        ),
      );
      return;
    }

    final updatedInterests = await Navigator.push<List<UserInterest>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditInterestsScreen(userId: userId, currentInterests: _interests),
      ),
    );

    if (updatedInterests != null && mounted) {
      setState(() => _interests = updatedInterests);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Preferències actualitzades correctament'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _navigateToNotificationPreferences() async {
    if (currentLoggedInUser == null || currentAuthToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cal iniciar sessió per accedir a la configuració.'),
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
      await _loadProfile(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemeTokens.screenBackground,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isOwnProfile ? 'El meu Perfil' : 'Perfil',
        style: AppThemeTokens.appBarTitle,
      ),
      backgroundColor: AppThemeTokens.appBarBackground,
      elevation: AppThemeTokens.appBarElevation,
      centerTitle: AppThemeTokens.appBarCenterTitle,
      automaticallyImplyLeading: !_isOwnProfile,
      iconTheme: AppThemeTokens.appBarIconTheme,
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
          : _buildOtherProfileActions(),
    );
  }

  /// Accions disponibles a l'AppBar quan veiem el perfil d'un altre usuari.
  /// El menú només es mostra si tenim un perfil carregat (cal saber l'estat
  /// de bloqueig per decidir l'etiqueta) i si no estem visitant el nostre
  /// propi perfil.
  List<Widget>? _buildOtherProfileActions() {
    final profile = _profile;
    if (profile == null) return null;
    if (_currentUserId == null || profile.id == _currentUserId) return null;

    final isBlocked = _friendshipStatus == FriendshipStatus.blocked;
    final actionLabel = isBlocked ? 'Desbloquejar' : 'Bloquejar';
    final actionIcon = isBlocked ? Icons.lock_open : Icons.block;

    return [
      PopupMenuButton<_ProfileMenuAction>(
        tooltip: 'Més opcions',
        icon: const Icon(Icons.more_vert, color: Colors.black87),
        enabled: !_isBlockActionInProgress,
        onSelected: (action) {
          switch (action) {
            case _ProfileMenuAction.toggleBlock:
              _toggleBlockStatus();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<_ProfileMenuAction>(
            value: _ProfileMenuAction.toggleBlock,
            child: Row(
              children: [
                Icon(
                  actionIcon,
                  size: 20,
                  color: isBlocked
                      ? Colors.green.shade700
                      : EventTextUtils.kPrimaryRed,
                ),
                const SizedBox(width: 12),
                Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isBlocked
                        ? Colors.green.shade800
                        : EventTextUtils.kPrimaryRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Punt d'entrada únic des del menú de perfil. Decideix entre bloquejar o
  /// desbloquejar segons l'estat actual:
  /// - Si el perfil està a la meva llista de bloquejats → desbloquejar.
  /// - Si no, bloquejar.
  /// Si l'estat encara no s'ha derivat (`null`), per defecte tractem com a
  /// "no bloquejat" perquè és la situació més habitual.
  Future<void> _toggleBlockStatus() async {
    if (_isBlockActionInProgress) return;
    if (!_ensureAuthenticatedForBlocking()) return;

    if (_friendshipStatus == FriendshipStatus.blocked) {
      await _confirmAndUnblockUser();
    } else {
      await _confirmAndBlockUser();
    }
  }

  /// Comprova que existeixi una sessió iniciada vàlida abans d'invocar
  /// l'API de bloqueig. Si no n'hi ha, mostra el missatge prescrit per
  /// la user story i avorta l'acció.
  bool _ensureAuthenticatedForBlocking() {
    final hasToken =
        currentAuthToken != null && currentAuthToken!.trim().isNotEmpty;
    final hasUser = _currentUserId != null;
    if (hasToken && hasUser) return true;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cal iniciar sessió per bloquejar usuaris.'),
      ),
    );
    return false;
  }

  /// Demana confirmació i, si l'usuari accepta, executa la crida POST
  /// `/api/users/{id}/block/`. En cas d'èxit:
  /// - Marca el perfil com a `FriendshipStatus.blocked` localment.
  /// - Invalida les llistes d'amistat (l'amistat es trenca al backend) i la
  ///   llista de bloquejats per refrescar la propera consulta.
  Future<void> _confirmAndBlockUser() async {
    final profile = _profile;
    if (profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bloquejar usuari'),
          content: Text(
            'Estàs segur/a que vols bloquejar @${profile.username}? '
            'Si ja sou amics, perdreu l\'amistat. No podrà enviar-te missatges, '
            'sol·licituds ni interactuar amb el teu contingut.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Bloquejar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _runBlockAction(
      action: () => blockUser(profile.id),
      successStatus: FriendshipStatus.blocked,
      successMessage: 'Has bloquejat aquest usuari.',
      genericErrorMessage: 'No s\'ha pogut bloquejar l\'usuari.',
      isUnblock: false,
    );
  }

  /// Demana confirmació i, si l'usuari accepta, executa la crida POST
  /// `/api/users/{id}/unblock/`. En cas d'èxit, l'estat passa a
  /// `FriendshipStatus.none` (no es restableix l'amistat: cal tornar a
  /// passar pel flux de sol·licitud).
  Future<void> _confirmAndUnblockUser() async {
    final profile = _profile;
    if (profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Desbloquejar usuari'),
          content: Text(
            'Vols desbloquejar @${profile.username}? Podrà veure el teu perfil '
            'i tornar a enviar-te missatges i sol·licituds d\'amistat. '
            'L\'amistat anterior no es restableix automàticament.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel·lar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Desbloquejar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await _runBlockAction(
      action: () => unblockUser(profile.id),
      successStatus: FriendshipStatus.none,
      successMessage: 'Has desbloquejat aquest usuari.',
      genericErrorMessage: 'No s\'ha pogut desbloquejar l\'usuari.',
      isUnblock: true,
      refreshChatsListOnSuccess: true,
    );
  }

  /// Executa una acció de bloqueig/desbloqueig i unifica la gestió d'errors,
  /// la sincronització de la caché del perfil i la invalidació de llistes.
  Future<void> _runBlockAction({
    required Future<BlockActionResult> Function() action,
    required FriendshipStatus successStatus,
    required String successMessage,
    required String genericErrorMessage,
    required bool isUnblock,
    bool refreshChatsListOnSuccess = false,
  }) async {
    setState(() => _isBlockActionInProgress = true);

    final result = await action();

    if (!mounted) return;

    switch (result) {
      case BlockActionSuccess():
        _applyBlockStateChange(
          newStatus: successStatus,
          message: successMessage,
          refreshChatsListOnSuccess: refreshChatsListOnSuccess,
        );
      case BlockActionUnauthorized():
        setState(() => _isBlockActionInProgress = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cal iniciar sessió per bloquejar usuaris.'),
          ),
        );
      case BlockActionUserNotFound():
        setState(() => _isBlockActionInProgress = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil no vàlid.')));
      case BlockActionConflict(:final message):
        // El backend ja considera l'acció aplicada (ja estava bloquejat o
        // desbloquejat). Sincronitzem la UI amb l'estat real.
        _applyBlockStateChange(
          newStatus: successStatus,
          message:
              message ??
              (isUnblock
                  ? 'Aquest usuari ja no estava bloquejat.'
                  : 'Aquest usuari ja estava bloquejat.'),
          refreshChatsListOnSuccess: refreshChatsListOnSuccess,
        );
      case BlockActionFailure(:final statusCode, :final message, :final error):
        setState(() => _isBlockActionInProgress = false);
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

  /// Aplica un canvi d'estat de bloqueig a la UI i a la caché compartida.
  void _applyBlockStateChange({
    required FriendshipStatus newStatus,
    required String message,
    bool refreshChatsListOnSuccess = false,
  }) {
    setState(() {
      _friendshipStatus = newStatus;
      if (_profile != null) {
        _profile = _profile!.copyWithFriendshipStatus(newStatus);
      }
      _isBlockActionInProgress = false;
    });

    final otherId = widget.userId;
    if (otherId != null) {
      // Sincronitza el perfil cachejat, els sets locals i la llista d'amics:
      // bloquejar trenca l'amistat al backend i ha de fer desaparèixer
      // l'usuari del nostre llistat sense esperar al següent refetch.
      _profileQuery.recordFriendshipStatusChange(
        otherId,
        newStatus,
        otherSummary: _profile?.toSummary(),
      );
    }

    // Bloquejar trenca l'amistat al backend i amaga l'usuari de les llistes
    // d'amics i sol·licituds. Desbloquejar deixa l'usuari fora de la llista
    // de bloquejats. En els dos casos cal invalidar les caches per evitar
    // mostrar dades obsoletes.
    final myId = _currentUserId;
    if (myId != null) {
      _profileQuery.invalidateFriendshipLists(myId);
      _profileQuery.invalidateBlockedUsers(myId);
    }

    if (refreshChatsListOnSuccess) {
      ChatsQuery.instance.invalidateChatsList();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ProfileLoadErrorBody(
        message: _errorMessage!,
        onRetry: () => _loadProfile(forceRefresh: true),
      );
    }

    final profile = _profile!;
    return RefreshIndicator(
      onRefresh: () => _loadProfile(forceRefresh: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppScreenSpacing.content,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileSummaryCard(
              profile: profile,
              stats: _stats,
              attendanceCount: _attendanceCount,
              reviewsCount: _reviewsCount,
              isOwnProfile: _isOwnProfile,
              onEditProfile: _navigateToEditProfile,
              friendshipSection: ProfileFriendshipSection(
                currentUserId: _currentUserId,
                viewedUserId: widget.userId,
                status: _friendshipStatus ?? FriendshipStatus.none,
                isFriendshipBusy: _isFriendshipActionInProgress,
                isBlockBusy: _isBlockActionInProgress,
                onSendFriendRequest: _sendFriendRequest,
                onCancelFriendRequest: _cancelFriendRequest,
                onAcceptFriendRequest: _acceptFriendRequest,
                onRejectFriendRequest: _rejectFriendRequest,
                onUnfriend: _confirmAndUnfriendUser,
                onUnblock: _confirmAndUnblockUser,
              ),
            ),
            const SizedBox(height: AppScreenSpacing.section),
            ProfileInterestsSection(
              isOwnProfile: _isOwnProfile,
              interests: _interests,
              onEditTap: _navigateToEditInterests,
            ),
            const SizedBox(height: AppScreenSpacing.section),
            _buildTabSection(reviewsResponse: _reviewsResponse),
            if (_isOwnProfile) ...[
              const SizedBox(height: AppScreenSpacing.section),
              _ProfileLogoutButton(
                isLoggingOut: _isLoggingOut,
                onPressed: _isLoggingOut ? null : _requestLogOut,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection({required UserReviewsResponse? reviewsResponse}) {
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
            labelColor: EventTextUtils.kPrimaryRed,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: EventTextUtils.kPrimaryRed,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              Tab(
                child: _ProfileAttendedTabLabel(
                  isOwnProfile: _isOwnProfile,
                  sessionsQuery: _sessionsQuery,
                ),
              ),
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
                ProfileAttendedSessionsTab(
                  isOwnProfile: _isOwnProfile,
                  sessionsQuery: _sessionsQuery,
                  eventsQuery: _eventsQuery,
                  onOpenSession: _openSessionEvent,
                ),
                ProfileReviewsTab(
                  response: reviewsResponse,
                  onReviewTap: _openReviewEvent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openReviewEvent(UserReview review) {
    final eventCode = review.eventCode;
    if (eventCode == null || eventCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aquesta ressenya no té esdeveniment.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventScreen(eventCode: eventCode)),
    );
  }

  void _openSessionEvent(Session session) {
    if (session.event.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aquesta sessió no té esdeveniment.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventScreen(eventCode: session.event)),
    );
  }
}

class _ProfileLoadErrorBody extends StatelessWidget {
  const _ProfileLoadErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: AppScreenSpacing.section),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: AppScreenSpacing.section),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLogoutButton extends StatelessWidget {
  const _ProfileLogoutButton({
    required this.isLoggingOut,
    required this.onPressed,
  });

  final bool isLoggingOut;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoggingOut
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_outlined),
        style: OutlinedButton.styleFrom(
          foregroundColor: EventTextUtils.kPrimaryRed,
          side: const BorderSide(color: EventTextUtils.kPrimaryRed),
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

class _ProfileAttendedTabLabel extends StatelessWidget {
  const _ProfileAttendedTabLabel({
    required this.isOwnProfile,
    required this.sessionsQuery,
  });

  final bool isOwnProfile;
  final SessionsQuery sessionsQuery;

  @override
  Widget build(BuildContext context) {
    if (!isOwnProfile) {
      return const Text('Assistits');
    }

    return FutureBuilder<List<Session>>(
      future: sessionsQuery.getSessions(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Assistits'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Accions disponibles al menú contextual del perfil d'un altre usuari.
/// Es deixa com a `enum` privat al fitxer perquè el menú només té sentit
/// dins del flux d'aquesta pantalla.
enum _ProfileMenuAction { toggleBlock }
