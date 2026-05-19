import 'dart:async';
import 'dart:typed_data';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/core/realtime/friendship_realtime_event.dart';
import 'package:agendat/core/state/pending_friend_requests_notifier.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';

class FriendshipChange {
  const FriendshipChange({
    required this.type,
    required this.counterpartId,
    required this.status,
    this.friendshipId,
    this.chatId,
  });

  final String type;
  final int counterpartId;
  final FriendshipStatus status;
  final int? friendshipId;
  final int? chatId;
}

class ProfileQuery {
  static final ProfileQuery instance = ProfileQuery._();
  ProfileQuery._();

  static const String _prefix = 'profile';
  static const Duration _profileStaleTime = Duration(minutes: 5);
  static const Duration _statsStaleTime = Duration(minutes: 5);
  static const Duration _interestsStaleTime = Duration(minutes: 30);
  static const Duration _reviewsStaleTime = Duration(minutes: 5);
  static const Duration _sessionsStaleTime = Duration(minutes: 5);
  static const Duration _friendshipStaleTime = Duration(minutes: 2);

  final QueryClient _client = QueryClient.instance;
  final StreamController<FriendshipChange> _friendshipChanges =
      StreamController<FriendshipChange>.broadcast();

  Stream<FriendshipChange> get friendshipChanges => _friendshipChanges.stream;

  int? get _currentUserId => currentLoggedInUser?['id'] as int?;

  /// Conjunt local d'ids d'usuaris que jo he bloquejat. Sobreviu a la
  /// invalidació de la query `'$_prefix:blocked:...'` i té tres usos:
  ///
  /// 1. Marcar un usuari com a bloquejat instantàniament després d'una crida
  ///    POST `/api/users/{id}/block/` exitosa, sense haver d'esperar el
  ///    refetch de `/blocked/`.
  /// 2. Filtrar les llistes d'amics, sol·licituds i resultats de cerca quan
  ///    el backend encara no ha cascadat la ruptura de l'amistat.
  /// 3. Donar immediatesa entre pantalles mentre la UI espera el refetch del
  ///    perfil (que ja porta `friendship_status`) o de la llista `/blocked/`.
  ///
  /// Només s'esborra un id mitjançant [markUserUnblocked] (mai per la
  /// resposta del backend) per no perdre estat optimista en cas de
  /// resposta parcial o intermitent.
  final Set<int> _localBlockedIds = <int>{};

  /// Conjunt local d'ids d'usuaris que han deixat de ser amics meus durant
  /// aquesta sessió. Serveix per amagar-los immediatament del llistat
  /// d'amics quan torno enrere des del perfil, sense esperar un refetch de
  /// `/friends/`.
  final Set<int> _localUnfriendedIds = <int>{};

  Future<ProfileResult> getUserProfile(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<ProfileResult>(
      key: '$_prefix:user:$userId',
      staleTime: _profileStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final result = await fetchUserProfile(userId);
        if (result is ProfileSuccess) {
          // El perfil retorna `friendship_status` autoritativament: el fem
          // servir com a font de veritat per sincronitzar caches locals (set
          // de bloquejats, set d'amistats eliminades i llista d'amics
          // cachejada). Així ens recuperem si l'altre usuari ha fet canvis
          // que el nostre client encara no havia pogut percebre (p. ex. ens
          // ha eliminat de la seva xarxa o ha acceptat la nostra sol·licitud
          // sense que sapiguéssim res).
          _applyBackendFriendshipState(result.profile);
        }
        return result;
      },
    );
  }

  /// Aplica l'estat d'amistat retornat pel backend (`friendship_status`) a
  /// les caches locals: conjunts d'ids (bloquejats, eliminats com a amic) i
  /// llista d'amics cachejada. No fa cap mutació si el perfil correspon a
  /// l'usuari autenticat (no té sentit comparar-se amb un mateix).
  void _applyBackendFriendshipState(UserProfile profile) {
    final myId = currentLoggedInUser?['id'];
    if (myId is! int || myId == profile.id) return;

    final status = profile.friendshipStatus;

    // [_localBlockedIds] només s'omple aquí (mai s'esborra). El backend pot
    // retornar `friendship_status: none` o ometre el camp per a usuaris que
    // jo he bloquejat (depèn de la implementació de `GET /api/users/{id}/`),
    // i si confiéssim en aquesta resposta per esborrar de la caché local
    // perdríem la informació recuperada via `bootstrapForAuthenticatedUser`
    // i la UI tornaria a mostrar "Enviar sol·licitud" a un usuari que tinc
    // bloquejat. La supressió només passa explícitament a través de
    // [markUserUnblocked] (i de [recordFriendshipStatusChange] quan
    // confirmem un desbloqueig al backend).
    if (status == FriendshipStatus.blockedByMe) {
      _localBlockedIds.add(profile.id);
    }

    // Si el backend confirma que som amics, descartem qualsevol marca local
    // que els amagués del llistat. Si confirma que NO som amics, no toquem
    // [_localUnfriendedIds] perquè la llista d'amics ja se sincronitza per
    // sota i el set és només una xarxa de seguretat per popups oberts amb
    // estat antic.
    if (status == FriendshipStatus.friends) {
      _localUnfriendedIds.remove(profile.id);
    }

    // Per al sync de la llista d'amics fem servir l'estat efectiu (incloent
    // el bloqueig local que el backend pot no estar reportant): així ens
    // assegurem que un usuari bloquejat que casualment encara consti com a
    // amic en una caché vella es retiri.
    final effectiveStatus = _localBlockedIds.contains(profile.id)
        ? FriendshipStatus.blockedByMe
        : status;
    _syncFriendsCacheForUser(
      myId,
      profile.id,
      effectiveStatus,
      profile.toSummary(),
    );
  }

  Future<UserStats> getUserStats(int userId, {bool forceRefresh = false}) {
    return _client.query<UserStats>(
      key: '$_prefix:stats:$userId',
      staleTime: _statsStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchUserStats(userId),
    );
  }

  Future<List<UserInterest>> getUserInterests(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<List<UserInterest>>(
      key: '$_prefix:interests:$userId',
      staleTime: _interestsStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchUserInterests(userId),
    );
  }

  Future<UpdateUserInterestsResult> updateInterests(
    int userId,
    List<int> categoryIds,
  ) async {
    final result = await updateUserInterests(userId, categoryIds);
    if (result is UpdateUserInterestsSuccess) {
      _client.setQueryData<List<UserInterest>>(
        '$_prefix:interests:$userId',
        result.interests,
      );
    }
    return result;
  }

  Future<UserReviewsResponse> getUserReviews(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<UserReviewsResponse>(
      key: '$_prefix:reviews:$userId',
      staleTime: _reviewsStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchUserReviews(userId),
    );
  }

  Future<List<Session>> getUserSessions({
    required String username,
    bool forceRefresh = false,
  }) {
    return _client.query<List<Session>>(
      key: '$_prefix:sessions:$username',
      staleTime: _sessionsStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchUserSessions(username: username),
    );
  }

  /// Mutation: PATCH /api/users/{id}/ amb només els camps que han canviat.
  /// Si té èxit, actualitza el cache del perfil i invalida les dades
  /// derivades (sessions, stats, interests, reviews) per mantenir-les
  /// coherents amb el nou estat.
  Future<UpdateProfileResult> updateProfile(
    int userId,
    Map<String, dynamic> updates, {
    Uint8List? profileImageBytes,
    String? profileImageFilename,
    String? profileImageContentType,
  }) async {
    final result = await updateUserProfile(
      userId,
      updates,
      profileImageBytes: profileImageBytes,
      profileImageFilename: profileImageFilename,
      profileImageContentType: profileImageContentType,
    );

    if (result is UpdateProfileSuccess) {
      _client.setQueryData<ProfileResult>(
        '$_prefix:user:$userId',
        ProfileSuccess(profile: result.profile),
      );
      // Les dades derivades depenen (directament o indirecta) del perfil,
      // així que les invalidem per forçar un refetch la propera vegada.
      _client.invalidate('$_prefix:stats:$userId');
      _client.invalidate('$_prefix:interests:$userId');
      _client.invalidate('$_prefix:reviews:$userId');
      _client.invalidatePrefix('$_prefix:sessions:');
    }

    return result;
  }

  /// Mutation: DELETE /api/users/{id}/. Si té èxit tanca la sessió local
  /// i neteja qualsevol cache vinculat a aquest usuari.
  Future<DeleteAccountResult> deleteAccount() async {
    final userId = currentLoggedInUser?['id'];
    if (currentLoggedInUser == null ||
        userId is! int ||
        userId.toString().trim().isEmpty) {
      return DeleteAccountFailure(statusCode: -1);
    }

    final result = await deleteUserAccount(userId);
    if (result is DeleteAccountSuccess) {
      invalidateUser(userId);
      _client.invalidatePrefix('$_prefix:sessions:');
      await logout();
    }
    return result;
  }

  void invalidateUser(int userId) {
    _client.invalidate('$_prefix:user:$userId');
    _client.invalidate('$_prefix:stats:$userId');
    _client.invalidate('$_prefix:interests:$userId');
    _client.invalidate('$_prefix:reviews:$userId');
  }

  /// Actualitza optimistament el camp `friendshipStatus` del perfil
  /// d'[userId] a la caché. Útil perquè si surts i tornes a entrar al perfil
  /// abans que expiri la caché, l'estat del botó sigui coherent.
  void setCachedFriendshipStatus(int userId, FriendshipStatus? status) {
    final current = _client.getQueryData<ProfileResult>(
      '$_prefix:user:$userId',
    );
    if (current is ProfileSuccess) {
      _client.setQueryData<ProfileResult>(
        '$_prefix:user:$userId',
        ProfileSuccess(
          profile: current.profile.copyWithFriendshipStatus(status),
        ),
      );
    }
  }

  void invalidateSessionsByUsername(String username) {
    _client.invalidate('$_prefix:sessions:$username');
  }

  /// GET /api/users/{userId}/friend-requests/ — cridat amb el meu id.
  Future<FriendRequestsData> getFriendRequests(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<FriendRequestsData>(
      key: '$_prefix:friend-requests:$userId',
      staleTime: _friendshipStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final data = await fetchFriendRequests(userId);
        if (_currentUserId == userId) {
          _syncPendingFriendRequestsBadge(data);
        }
        return data;
      },
    );
  }

  /// GET /api/users/{userId}/friends/ — es pot cridar amb el meu id per saber
  /// quins són els meus amics i derivar l'estat d'amistat amb qualsevol perfil.
  Future<List<UserSummary>> getFriends(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<List<UserSummary>>(
      key: '$_prefix:friends:$userId',
      staleTime: _friendshipStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchFriends(userId),
    );
  }

  /// GET /api/users/friend-recommendations/ — recomanacions per a l'usuari
  /// autenticat. La clau inclou el meu id per evitar barrejar recomanacions
  /// si canvia la sessió dins la mateixa instància de l'app.
  Future<FriendRecommendationsData> getFriendRecommendations({
    bool forceRefresh = false,
  }) {
    final myId = currentLoggedInUser?['id'];
    if (myId is! int) {
      return Future.value(FriendRecommendationsData.empty);
    }

    return _client.query<FriendRecommendationsData>(
      key: '$_prefix:friend-recommendations:$myId',
      staleTime: _friendshipStaleTime,
      forceRefresh: forceRefresh,
      queryFn: fetchFriendRecommendations,
    );
  }

  /// Neteja les llistes d'amistat i sol·licituds de l'usuari actual per forçar
  /// un refetch la propera vegada. Cal cridar-lo quan envies/canceles/acceptes
  /// una sol·licitud o quan l'estat d'amistat canvia des del backend.
  void invalidateFriendshipLists(int userId) {
    _client.invalidate('$_prefix:friend-requests:$userId');
    _client.invalidate('$_prefix:friends:$userId');
  }

  /// Invalida només la llista de sol·licituds d'amistat de l'usuari [userId].
  /// Útil després d'una mutació que afecta una sol·licitud (acceptar,
  /// rebutjar, enviar, cancel·lar) i en què la llista d'amics ja s'ha
  /// sincronitzat optimísticament per altres camins.
  void invalidateFriendRequestsList(int userId) {
    _client.invalidate('$_prefix:friend-requests:$userId');
  }

  /// Invalida les recomanacions d'amistat de l'usuari autenticat.
  void invalidateFriendRecommendations() {
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      _client.invalidate('$_prefix:friend-recommendations:$myId');
    }
  }

  /// Sincronitza la caché del client després d'un canvi confirmat (per crida
  /// pròpia, no per refetch de backend) en l'estat d'amistat amb [userId]:
  ///
  /// - Actualitza el camp `friendshipStatus` del perfil cachejat.
  /// - Afegeix o esborra l'usuari de [_localBlockedIds] segons si està
  ///   bloquejat.
  /// - Afegeix o esborra l'usuari de [_localUnfriendedIds] segons si la nova
  ///   relació és d'amistat o no (la xarxa de seguretat per a popups amb
  ///   estat antic).
  /// - Manté la llista d'amics cachejada coherent amb el nou estat: hi afegeix
  ///   [otherSummary] si ara som amics i encara no hi era, o l'esborra si
  ///   deixem de ser-ho.
  ///
  /// Aquesta crida NO toca la caché de sol·licituds d'amistat: si la mutació
  /// modifica les llistes `sent`/`received`, cal invocar separadament
  /// [invalidateFriendRequestsList].
  void recordFriendshipStatusChange(
    int userId,
    FriendshipStatus? status, {
    UserSummary? otherSummary,
  }) {
    final applied = _applyFriendshipStatusChange(
      userId,
      status,
      otherSummary: otherSummary,
    );
    if (!applied || status == null) return;

    _emitFriendshipChange(type: 'local', counterpartId: userId, status: status);
  }

  Future<void> applyFriendshipRealtimeEvent(
    FriendshipRealtimeEvent event,
  ) async {
    if (event is! FriendshipRealtimeMutationEvent) return;

    final myId = _currentUserId;
    if (myId == null) return;

    switch (event) {
      case FriendRequestCreatedEvent():
        _upsertFriendRequestFromRealtime(
          myId,
          event.friendshipStatus,
          event.counterpart,
          event.friendshipId,
          event.requestSnapshot,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          event.friendshipStatus,
          otherSummary: event.counterpart,
        );
        break;
      case FriendRequestAcceptedEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          FriendshipStatus.friends,
          otherSummary: event.counterpart,
        );
        await ChatsQuery.instance.hydrateAcceptedFriendshipChat(event.chatId);
        break;
      case FriendRequestRejectedEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          FriendshipStatus.none,
          otherSummary: event.counterpart,
        );
        break;
      case FriendRequestCancelledEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          FriendshipStatus.none,
          otherSummary: event.counterpart,
        );
        break;
      case FriendshipBlockedEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          event.friendshipStatus,
          otherSummary: event.counterpart,
        );
        if (event.friendshipStatus == FriendshipStatus.blockedByMe) {
          _upsertBlockedUserCache(myId, event.counterpart);
        }
        break;
      case FriendshipUnblockedEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        if (event.actorId == myId) {
          _removeBlockedUserFromCache(myId, event.counterpart.id);
        }
        _applyFriendshipStatusChange(
          event.counterpart.id,
          FriendshipStatus.none,
          otherSummary: event.counterpart,
        );
        break;
      case FriendshipUnfriendedEvent():
        _removeFriendRequestFromCaches(
          myId,
          event.counterpart.id,
          event.friendshipId,
        );
        _applyFriendshipStatusChange(
          event.counterpart.id,
          FriendshipStatus.none,
          otherSummary: event.counterpart,
        );
        break;
      default:
        break;
    }

    _emitFriendshipChange(
      type: event.type,
      counterpartId: event.counterpart.id,
      status: event.friendshipStatus,
      friendshipId: event.friendshipId,
      chatId: event.chatId,
    );
  }

  /// Aplica el nou [status] d'amistat amb [otherId] a la llista d'amics
  /// cachejada de [myId]. Si la caché no existeix, no fa res: la pròxima
  /// lectura ja farà un refetch fresc del backend.
  ///
  /// - Si ara som amics i l'usuari no hi és, l'afegeix (cal [otherSummary]).
  ///   Si no se'n proporciona cap, invalida la caché perquè el següent
  ///   `getFriends` el recuperi del backend.
  /// - Si ara NO som amics i l'usuari hi és, el filtra de la caché.
  void _syncFriendsCacheForUser(
    int myId,
    int otherId,
    FriendshipStatus? status,
    UserSummary? otherSummary,
  ) {
    final friendsKey = '$_prefix:friends:$myId';
    final cached = _client.getQueryData<List<UserSummary>>(friendsKey);
    if (cached == null) return;

    final hasUser = cached.any((u) => u.id == otherId);
    final shouldBeFriend = status == FriendshipStatus.friends;

    if (shouldBeFriend && !hasUser) {
      if (otherSummary != null) {
        _client.setQueryData<List<UserSummary>>(friendsKey, [
          ...cached,
          otherSummary,
        ]);
      } else {
        // No tenim representació prou rica de l'usuari per inserir-lo a la
        // llista. Invalidem la caché per forçar un refetch el següent cop
        // que es consulti.
        _client.invalidate(friendsKey);
      }
    } else if (!shouldBeFriend && hasUser) {
      _client.setQueryData<List<UserSummary>>(
        friendsKey,
        cached.where((u) => u.id != otherId).toList(),
      );
    }
  }

  /// GET /api/users/{userId}/blocked/ — llistat d'usuaris que jo he bloquejat.
  /// Es fa servir per derivar l'estat de bloqueig amb un perfil concret.
  ///
  /// La resposta del backend s'integra dins de [_localBlockedIds] (només per
  /// afegir, mai per esborrar) per assegurar que l'estat optimista local no
  /// es perdi davant respostes parcials o errors esporàdics.
  Future<List<UserSummary>> getBlockedUsers(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<List<UserSummary>>(
      key: '$_prefix:blocked:$userId',
      staleTime: _friendshipStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final users = await fetchBlockedUsers(userId);
        for (final u in users) {
          _localBlockedIds.add(u.id);
        }
        return users;
      },
    );
  }

  /// Invalida la llista de bloquejats d'un usuari per forçar un refetch
  /// la propera vegada que es consulti. No toca [_localBlockedIds].
  void invalidateBlockedUsers(int userId) {
    _client.invalidate('$_prefix:blocked:$userId');
  }

  /// Marca [targetId] com a bloquejat localment. Cal cridar-lo després d'una
  /// crida POST `/api/users/{id}/block/` exitosa per actualitzar la UI sense
  /// esperar el refetch de `/blocked/`.
  void markUserBlocked(int targetId) {
    _localBlockedIds.add(targetId);
  }

  /// Esborra [targetId] de la caché local de bloquejats. Cal cridar-lo
  /// després d'una crida POST `/api/users/{id}/unblock/` exitosa.
  void markUserUnblocked(int targetId) {
    _localBlockedIds.remove(targetId);
  }

  /// Marca [targetId] com a amistat eliminada localment. La llista d'amics el
  /// filtrarà encara que la query cachejada de `/friends/` segueixi retornant
  /// la versió anterior fins al següent refetch.
  void markUserUnfriended(int targetId) {
    _localUnfriendedIds.add(targetId);
  }

  /// Esborra [targetId] del conjunt local d'amistats eliminades. Cal cridar-lo
  /// quan una relació torna a existir (p. ex. després d'acceptar una nova
  /// sol·licitud d'amistat).
  void markUserRefriended(int targetId) {
    _localUnfriendedIds.remove(targetId);
  }

  /// `true` si [targetId] consta com a bloquejat localment. La consulta es
  /// fa a memòria, sense crides de xarxa.
  bool isUserLocallyBlocked(int targetId) {
    return _localBlockedIds.contains(targetId);
  }

  /// Vista immutable del conjunt local de bloquejats. Útil per filtrar
  /// llistes (amics, resultats de cerca, sol·licituds) sense exposar el
  /// `Set` mutable subjacent.
  Set<int> get locallyBlockedUserIds => Set.unmodifiable(_localBlockedIds);

  /// Vista immutable de les amistats eliminades localment. Permet filtrar
  /// llistes sense exposar el `Set` mutable subjacent.
  Set<int> get locallyUnfriendedUserIds =>
      Set.unmodifiable(_localUnfriendedIds);

  void invalidateAll() => _client.invalidatePrefix(_prefix);

  /// Inicialitza les caches que han de ser coherents amb la sessió
  /// autenticada actual. Cal cridar-lo en dos casos:
  ///
  /// - Després d'iniciar sessió (ja sigui per credencials o per Google),
  ///   abans de mostrar la primera pantalla autenticada.
  /// - Després de restaurar una sessió persistida en arrencar l'app.
  ///
  /// El mètode buida l'estat residual (els conjunts locals i la caché del
  /// `QueryClient` viuen com a singletons en memòria i sobreviuen a
  /// `logout`), i tot seguit força el fetch del llistat d'usuaris bloquejats
  /// per repoblar `_localBlockedIds`. Sense això, després d'un reinici de
  /// l'app o d'un canvi d'usuari, els perfils dels usuaris que havíem
  /// bloquejat no es marquen correctament com a `blocked` (el backend pot
  /// retornar `friendship_status: none` o ometre el camp), i la UI ofereix
  /// "Enviar sol·licitud" en comptes de "Desbloquejar".
  Future<void> bootstrapForAuthenticatedUser(int userId) async {
    // Comencem amb caches netes: si un altre usuari havia iniciat sessió en
    // aquesta mateixa instància de l'app, els seus ids bloquejats no han de
    // contaminar la sessió nova.
    _localBlockedIds.clear();
    _localUnfriendedIds.clear();
    _client.invalidatePrefix(_prefix);

    // Repoblar la caché local d'usuaris bloquejats és la font de veritat per
    // a la decisió "puc enviar sol·licitud" vs "he de desbloquejar". Si el
    // fetch falla (xarxa, 5xx) ho deixem en silenci: la propera vegada que
    // l'usuari obri el llistat de bloquejats o intenti una acció amb un
    // usuari concret (rebrà una resposta del backend i la caché es
    // corregirà sola).
    try {
      await getBlockedUsers(userId, forceRefresh: true);
    } catch (_) {
      // Best-effort: no volem trencar el flux d'inici de sessió per culpa
      // d'una crida derivada que pot reintentar-se més tard.
    }
  }

  bool _applyFriendshipStatusChange(
    int userId,
    FriendshipStatus? status, {
    UserSummary? otherSummary,
  }) {
    if (status == null) return false;

    setCachedFriendshipStatus(userId, status);

    switch (status) {
      case FriendshipStatus.blockedByMe:
        _localBlockedIds.add(userId);
        _localUnfriendedIds.remove(userId);
        break;
      case FriendshipStatus.friends:
        _localBlockedIds.remove(userId);
        _localUnfriendedIds.remove(userId);
        break;
      case FriendshipStatus.blockedMe:
        _localBlockedIds.remove(userId);
        _localUnfriendedIds.add(userId);
        break;
      case FriendshipStatus.none:
        _localBlockedIds.remove(userId);
        _localUnfriendedIds.add(userId);
        break;
      case FriendshipStatus.requestSent:
      case FriendshipStatus.requestReceived:
        _localBlockedIds.remove(userId);
        break;
    }

    final myId = _currentUserId;
    if (myId != null && myId != userId) {
      _syncFriendsCacheForUser(myId, userId, status, otherSummary);
    }

    switch (status) {
      case FriendshipStatus.friends:
      case FriendshipStatus.none:
      case FriendshipStatus.blockedByMe:
      case FriendshipStatus.blockedMe:
        ChatsQuery.instance.syncPartnerFriendshipStateInCache(
          userId,
          status: status,
        );
        break;
      case FriendshipStatus.requestSent:
      case FriendshipStatus.requestReceived:
        break;
    }

    _syncRecommendationsForStatusChange(userId, status);
    return true;
  }

  void _syncRecommendationsForStatusChange(
    int userId,
    FriendshipStatus status,
  ) {
    final myId = _currentUserId;
    if (myId == null) return;

    switch (status) {
      case FriendshipStatus.none:
        invalidateFriendRecommendations();
        break;
      case FriendshipStatus.requestSent:
      case FriendshipStatus.requestReceived:
      case FriendshipStatus.friends:
      case FriendshipStatus.blockedByMe:
      case FriendshipStatus.blockedMe:
        final key = '$_prefix:friend-recommendations:$myId';
        final cached = _client.getQueryData<FriendRecommendationsData>(key);
        if (cached == null) return;
        final next = cached.recommendations
            .where((recommendation) => recommendation.id != userId)
            .toList();
        if (next.length == cached.recommendations.length) return;
        _client.setQueryData<FriendRecommendationsData>(
          key,
          FriendRecommendationsData(
            count: next.length,
            recommendations: next,
            detail: cached.detail,
          ),
        );
        break;
    }
  }

  void _upsertFriendRequestFromRealtime(
    int myId,
    FriendshipStatus status,
    UserSummary counterpart,
    int friendshipId,
    PendingFriendRequest? requestSnapshot,
  ) {
    final current =
        _client.getQueryData<FriendRequestsData>(
          '$_prefix:friend-requests:$myId',
        ) ??
        FriendRequestsData.empty;
    final request =
        requestSnapshot ??
        PendingFriendRequest(
          id: friendshipId,
          status: 'pending',
          counterpart: counterpart,
          requestedBy: status == FriendshipStatus.requestReceived
              ? counterpart
              : null,
          createdAt: DateTime.now(),
        );

    final sent = _removeMatchingRequests(
      current.sent,
      counterpart.id,
      friendshipId,
    );
    final received = _removeMatchingRequests(
      current.received,
      counterpart.id,
      friendshipId,
    );

    final next = switch (status) {
      FriendshipStatus.requestSent => FriendRequestsData(
        sent: [request, ...sent],
        received: received,
      ),
      FriendshipStatus.requestReceived => FriendRequestsData(
        sent: sent,
        received: [request, ...received],
      ),
      _ => FriendRequestsData(sent: sent, received: received),
    };

    _client.setQueryData<FriendRequestsData>(
      '$_prefix:friend-requests:$myId',
      next,
    );
    _syncPendingFriendRequestsBadge(next);
  }

  void _removeFriendRequestFromCaches(
    int myId,
    int counterpartId,
    int friendshipId,
  ) {
    final current =
        _client.getQueryData<FriendRequestsData>(
          '$_prefix:friend-requests:$myId',
        ) ??
        FriendRequestsData.empty;
    final next = FriendRequestsData(
      sent: _removeMatchingRequests(current.sent, counterpartId, friendshipId),
      received: _removeMatchingRequests(
        current.received,
        counterpartId,
        friendshipId,
      ),
    );
    _client.setQueryData<FriendRequestsData>(
      '$_prefix:friend-requests:$myId',
      next,
    );
    _syncPendingFriendRequestsBadge(next);
  }

  List<PendingFriendRequest> _removeMatchingRequests(
    List<PendingFriendRequest> requests,
    int counterpartId,
    int friendshipId,
  ) {
    return requests
        .where(
          (request) =>
              request.id != friendshipId &&
              _requestCounterpartId(request) != counterpartId,
        )
        .toList();
  }

  int? _requestCounterpartId(PendingFriendRequest request) {
    return request.counterpart?.id ??
        request.requestedBy?.id ??
        request.blockedBy?.id;
  }

  void _upsertBlockedUserCache(int myId, UserSummary counterpart) {
    final key = '$_prefix:blocked:$myId';
    final cached = _client.getQueryData<List<UserSummary>>(key);
    if (cached == null) return;
    if (cached.any((user) => user.id == counterpart.id)) return;
    _client.setQueryData<List<UserSummary>>(key, [counterpart, ...cached]);
  }

  void _removeBlockedUserFromCache(int myId, int counterpartId) {
    final key = '$_prefix:blocked:$myId';
    final cached = _client.getQueryData<List<UserSummary>>(key);
    if (cached == null) return;
    _client.setQueryData<List<UserSummary>>(
      key,
      cached.where((user) => user.id != counterpartId).toList(),
    );
  }

  void _syncPendingFriendRequestsBadge(FriendRequestsData data) {
    final pending = data.received
        .where((request) => request.status.toLowerCase() == 'pending')
        .length;
    syncPendingFriendRequestsBadge(pending);
  }

  void _emitFriendshipChange({
    required String type,
    required int counterpartId,
    required FriendshipStatus status,
    int? friendshipId,
    int? chatId,
  }) {
    _friendshipChanges.add(
      FriendshipChange(
        type: type,
        counterpartId: counterpartId,
        status: status,
        friendshipId: friendshipId,
        chatId: chatId,
      ),
    );
  }
}
