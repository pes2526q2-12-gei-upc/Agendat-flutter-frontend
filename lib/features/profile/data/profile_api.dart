import 'dart:convert';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:http/http.dart' as http;

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
  final uri = Uri.parse('${getBaseUrl()}/api/users/$userId/');
  try {
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(decoded);

      return ProfileSuccess(profile: profile);
    }

    if (response.statusCode == 404) {
      return ProfileNotFound();
    }

    // Perfil desactivat (403) o eliminat (410)
    if (response.statusCode == 403 || response.statusCode == 410) {
      return ProfileUnavailable();
    }

    return ProfileFailure(statusCode: response.statusCode);
  } catch (e) {
    return ProfileFailure(statusCode: -1, error: e);
  }
}

Future<UserStats> fetchUserStats(int userId) async {
  final uri = Uri.parse('${getBaseUrl()}/api/users/$userId/stats/');
  final response = await http.get(
    uri,
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load stats (status ${response.statusCode})');
  }
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return UserStats.fromJson(decoded);
}

Future<List<UserInterest>> fetchUserInterests(int userId) async {
  final uri = Uri.parse('${getBaseUrl()}/api/users/$userId/interests/');
  final response = await http.get(
    uri,
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load interests (status ${response.statusCode})');
  }
  final decoded = jsonDecode(response.body) as List<dynamic>;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(UserInterest.fromJson)
      .toList();
}

Future<UserReviewsResponse> fetchUserReviews(int userId) async {
  final uri = Uri.parse('${getBaseUrl()}/api/users/$userId/reviews/');
  final response = await http.get(
    uri,
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load reviews (status ${response.statusCode})');
  }
  final decoded = jsonDecode(response.body) as Map<String, dynamic>;
  return UserReviewsResponse.fromJson(decoded);
}

/// "Attended events" are represented by Sessions.
/// Uses GET /api/sessions/?user=<username>
Future<List<UserSession>> fetchUserSessions({required String username}) async {
  final uri = Uri.parse('${getBaseUrl()}/api/sessions/?user=$username');
  final response = await http.get(
    uri,
    headers: const {'Accept': 'application/json'},
  );
  if (response.statusCode != 200) {
    throw Exception('Failed to load sessions (status ${response.statusCode})');
  }
  final decoded = jsonDecode(response.body) as List<dynamic>;
  return decoded
      .whereType<Map<String, dynamic>>()
      .map(UserSession.fromJson)
      .toList();
}
