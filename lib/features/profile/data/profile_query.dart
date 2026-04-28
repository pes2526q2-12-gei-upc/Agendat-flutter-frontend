import 'dart:typed_data';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';

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
          // Amb `friendship_status` al perfil, podem mantenir la caché local
          // de bloquejats sincronitzada amb la resposta autoritativa.
          if (result.profile.friendshipStatus == FriendshipStatus.blocked) {
            _localBlockedIds.add(userId);
          } else {
            _localBlockedIds.remove(userId);
          }
        }
        return result;
      },
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
      queryFn: () => fetchFriendRequests(userId),
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

  /// Neteja les llistes d'amistat i sol·licituds de l'usuari actual per forçar
  /// un refetch la propera vegada. Cal cridar-lo quan envies/canceles/acceptes
  /// una sol·licitud o quan l'estat d'amistat canvia des del backend.
  void invalidateFriendshipLists(int userId) {
    _client.invalidate('$_prefix:friend-requests:$userId');
    _client.invalidate('$_prefix:friends:$userId');
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
}
