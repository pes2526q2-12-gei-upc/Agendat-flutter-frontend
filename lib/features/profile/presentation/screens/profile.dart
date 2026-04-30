import 'package:flutter/material.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:agendat/features/profile/presentation/screens/edit_interests_screen.dart';
import 'package:agendat/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:agendat/features/profile/presentation/screens/settings_screen.dart';
import 'package:agendat/features/social/data/social_api.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
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
  UserReviewsResponse? _reviewsResponse;
  String? _errorMessage;
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  FriendshipStatus? _friendshipStatus;
  bool _isFriendshipActionInProgress = false;
  bool _isBlockActionInProgress = false;

  bool get _isOwnProfile => widget.userId == null;

  int? get _currentUserId => currentLoggedInUser?['id'] as int?;

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
            .getUserReviews(
              userId,
              // Les ressenyes es mostren en una pestanya dinàmica del perfil.
              // Forcem refetch per evitar quedar-nos amb caché buida/obsoleta.
              forceRefresh: true,
            )
            .catchError((_) {
              return const UserReviewsResponse(count: 0, reviews: []);
            });

        final derivedStatus = _resolveFriendshipStatus(profile: profile);

        if (!mounted) return;

        setState(() {
          _profile = profile;
          _stats = stats;
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
        // Sincronitza la caché del client (perfil cachejat, conjunts locals
        // i llista d'amics) amb el nou estat. La llista d'amics s'actualitza
        // optimísticament — si acceptem una sol·licitud o eliminem amistat,
        // veurem el canvi a l'instant la pròxima vegada que obrim el llistat
        // sense haver d'esperar un refetch ni el `staleTime`.
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
              style: FilledButton.styleFrom(backgroundColor: _kPrimaryRed),
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
      });
    }
  }

  Future<void> _navigateToEditInterests() async {
    final profile = _profile;
    if (profile == null) return;

    final updatedInterests = await Navigator.push<List<UserInterest>>(
      context,
      MaterialPageRoute(
        builder: (_) => EditInterestsScreen(
          userId: profile.id,
          currentInterests: _interests,
        ),
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
                  color: isBlocked ? Colors.green.shade700 : _kPrimaryRed,
                ),
                const SizedBox(width: 12),
                Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isBlocked ? Colors.green.shade800 : _kPrimaryRed,
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
              style: FilledButton.styleFrom(backgroundColor: _kPrimaryRed),
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
  }) async {
    setState(() => _isBlockActionInProgress = true);

    final result = await action();

    if (!mounted) return;

    switch (result) {
      case BlockActionSuccess():
        _applyBlockStateChange(
          newStatus: successStatus,
          message: successMessage,
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

    // Sol·licituds i bloquejats poden haver canviat al backend; els
    // invalidem perquè les properes consultes recuperin valors frescos.
    final myId = _currentUserId;
    if (myId != null) {
      _profileQuery.invalidateFriendRequestsList(myId);
      _profileQuery.invalidateBlockedUsers(myId);
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: AppScreenSpacing.section),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: AppScreenSpacing.section),
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
        padding: AppScreenSpacing.content,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(profile),
            const SizedBox(height: AppScreenSpacing.section),
            _buildInterestsSection(_interests),
            const SizedBox(height: AppScreenSpacing.section),
            _buildTabSection(reviewsResponse: _reviewsResponse),
            if (_isOwnProfile) ...[
              const SizedBox(height: AppScreenSpacing.section),
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
        return _buildFriendshipOutlinedButton(
          onPressed: busy ? null : _confirmAndUnfriendUser,
          icon: Icons.person_remove_outlined,
          label: 'Eliminar amistat',
          busy: busy,
        );
      case FriendshipStatus.blocked:
        // Substituïm la badge informativa per un botó d'acció: l'única
        // operació útil sobre un usuari bloquejat és tornar-lo a desbloquejar,
        // i així evitem haver d'obrir el menú de tres punts. La confirmació
        // continua sent obligatòria abans de fer la crida POST `/unblock/`.
        // Fem servir `_isBlockActionInProgress` (no el d'amistat) com a
        // indicador d'ocupació, perquè correspon a l'acció subjacent.
        return _buildFriendshipOutlinedButton(
          onPressed: _isBlockActionInProgress ? null : _confirmAndUnblockUser,
          icon: Icons.lock_open,
          label: 'Desbloquejar',
          busy: _isBlockActionInProgress,
        );
    }
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
                  onTap: _navigateToEditInterests,
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
                _buildAttendedSessionsTab(),
                _buildReviewsTab(reviewsResponse),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedSessionsTab() {
    // Pendent d'implementar endpoint al backend per recuperar assistències
    // d'un usuari i mostrar-les al perfil.
    return _buildEmptyTabContent(
      'Assistències pendents de backend',
      Icons.event_outlined,
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
          onTap: () => _openReviewEvent(r),
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.rate_review, color: Colors.grey.shade600),
          title: Text(
            r.reviewerUsername.isEmpty ? 'Usuari' : r.reviewerUsername,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(r.comment.isEmpty ? '—' : r.comment),
        );
      },
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

/// Accions disponibles al menú contextual del perfil d'un altre usuari.
/// Es deixa com a `enum` privat al fitxer perquè el menú només té sentit
/// dins del flux d'aquesta pantalla.
enum _ProfileMenuAction { toggleBlock }
