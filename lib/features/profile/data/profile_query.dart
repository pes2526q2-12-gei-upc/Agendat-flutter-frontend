import 'dart:typed_data';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';

class ProfileQuery {
  static final ProfileQuery instance = ProfileQuery._();
  ProfileQuery._();

  static const String _prefix = 'profile';
  static const Duration _profileStaleTime = Duration(minutes: 5);
  static const Duration _statsStaleTime = Duration(minutes: 5);
  static const Duration _interestsStaleTime = Duration(minutes: 30);
  static const Duration _reviewsStaleTime = Duration(minutes: 5);
  static const Duration _sessionsStaleTime = Duration(minutes: 5);

  final QueryClient _client = QueryClient.instance;

  Future<ProfileResult> getUserProfile(
    int userId, {
    bool forceRefresh = false,
  }) {
    return _client.query<ProfileResult>(
      key: '$_prefix:user:$userId',
      staleTime: _profileStaleTime,
      forceRefresh: forceRefresh,
      queryFn: () => fetchUserProfile(userId),
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

  void invalidateSessionsByUsername(String username) {
    _client.invalidate('$_prefix:sessions:$username');
  }

  void invalidateAll() => _client.invalidatePrefix(_prefix);
}
