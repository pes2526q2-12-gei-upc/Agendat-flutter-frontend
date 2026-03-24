import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';

sealed class ProfileResult {}

class ProfileSuccess extends ProfileResult {
  ProfileSuccess({required this.profile});
  final UserProfile profile;
}

class ProfileNotFound extends ProfileResult {}

class ProfileUnavailable extends ProfileResult {}

class ProfileFailure extends ProfileResult {
  ProfileFailure({required this.statusCode, this.error});
  final int statusCode;
  final Object? error;
}

///Crida GET /api/users/{id}/ per obtenir les dades del perfil.
Future<ProfileResult> fetchUserProfile(int userId) async {
  try {
    final response = await ApiClient.get('/api/users/$userId/');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = UserProfile.fromJson(decoded);
    return ProfileSuccess(profile: profile);
  } on ApiException catch (e) {
    if (e.statusCode == 404) return ProfileNotFound();
    if (e.statusCode == 403 || e.statusCode == 410) return ProfileUnavailable();
    return ProfileFailure(statusCode: e.statusCode);
  } catch (e) {
    return ProfileFailure(statusCode: -1, error: e);
  }
}

Future<UserStats> fetchUserStats(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/stats/');
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return UserStats.fromJson(decoded);
}

Future<List<UserInterest>> fetchUserInterests(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/interests/');
  final decoded = jsonDecode(response.body) as List<dynamic>;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(UserInterest.fromJson)
      .toList();
}

Future<UserReviewsResponse> fetchUserReviews(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/reviews/');
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return UserReviewsResponse.fromJson(decoded);
}

/// "Attended events" are represented by Sessions.
/// Uses GET /api/sessions/?user=<username>
Future<List<UserSession>> fetchUserSessions({required String username}) async {
  final response = await ApiClient.get(
    '/api/sessions/',
    queryParams: {'user': username},
  );
  final decoded = jsonDecode(response.body) as List<dynamic>;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(UserSession.fromJson)
      .toList();
}
