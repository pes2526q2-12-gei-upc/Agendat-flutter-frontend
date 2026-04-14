import 'dart:convert';
import 'dart:typed_data';

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

sealed class UpdateProfileResult {}

class UpdateProfileSuccess extends UpdateProfileResult {
  UpdateProfileSuccess({required this.profile});
  final UserProfile profile;
}

class UpdateProfileValidationError extends UpdateProfileResult {
  UpdateProfileValidationError({required this.field, required this.message});
  final String field;
  final String message;
}

class UpdateProfileFailure extends UpdateProfileResult {
  UpdateProfileFailure({required this.statusCode, this.error});
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

/// Actualitza el perfil d'usuari amb PATCH /api/users/{id}/
Future<UpdateProfileResult> updateUserProfile(
  int userId,
  Map<String, dynamic> updates, {
  Uint8List? profileImageBytes,
  String? profileImageFilename,
  String? profileImageContentType,
}) async {
  try {
    final hasImage = profileImageBytes != null && profileImageBytes.isNotEmpty;
    final response = hasImage
        ? await ApiClient.patchMultipart(
            '/api/users/$userId/',
            fields: updates.map(
              (key, value) => MapEntry(key, value?.toString() ?? ''),
            ),
            files: [
              ApiClient.multipartFileFromBytes(
                field: 'imatge',
                bytes: profileImageBytes,
                filename: profileImageFilename ?? 'profile_image.jpg',
                contentType: profileImageContentType ?? 'image/jpeg',
              ),
            ],
          )
        : await ApiClient.patchJson('/api/users/$userId/', body: updates);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final profile = UserProfile.fromJson(decoded);
    return UpdateProfileSuccess(profile: profile);
  } on ApiException catch (e) {
    if (e.statusCode == 400) {
      try {
        final body = jsonDecode(e.body) as Map<String, dynamic>;
        if (body['email'] != null) {
          return UpdateProfileValidationError(
            field: 'email',
            message: _extractErrorMessage(body['email']),
          );
        }
        if (body['username'] != null) {
          return UpdateProfileValidationError(
            field: 'username',
            message: _extractErrorMessage(body['username']),
          );
        }
        if (body['password'] != null) {
          return UpdateProfileValidationError(
            field: 'password',
            message: _extractErrorMessage(body['password']),
          );
        }
      } catch (_) {}
    }
    return UpdateProfileFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return UpdateProfileFailure(statusCode: -1, error: e);
  }
}

String _extractErrorMessage(dynamic value) {
  if (value is List && value.isNotEmpty) {
    return value.first.toString();
  }
  return value.toString();
}
