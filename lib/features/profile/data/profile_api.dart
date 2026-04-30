import 'dart:convert';
import 'dart:typed_data';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/session_dto.dart';
import 'package:agendat/core/mappers/session_mapper.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';

sealed class DeleteAccountResult {}

class DeleteAccountSuccess extends DeleteAccountResult {}

class DeleteAccountUnauthorized extends DeleteAccountResult {}

class DeleteAccountFailure extends DeleteAccountResult {
  DeleteAccountFailure({required this.statusCode});
  final int statusCode;
}

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

sealed class UpdateUserInterestsResult {}

class UpdateUserInterestsSuccess extends UpdateUserInterestsResult {
  UpdateUserInterestsSuccess({required this.message, required this.interests});

  final String message;
  final List<UserInterest> interests;
}

class UpdateUserInterestsFailure extends UpdateUserInterestsResult {
  UpdateUserInterestsFailure({required this.statusCode, this.error});

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

Future<UpdateUserInterestsResult> updateUserInterests(
  int userId,
  List<int> categoryIds,
) async {
  try {
    final response = await ApiClient.putJson(
      '/api/users/$userId/interests/',
      body: {'category_ids': categoryIds},
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawInterests = decoded['interests'] as List<dynamic>? ?? const [];
    final interests = rawInterests
        .whereType<Map<String, dynamic>>()
        .map(UserInterest.fromJson)
        .toList();

    return UpdateUserInterestsSuccess(
      message:
          decoded['message'] as String? ??
          'Preferències actualitzades correctament',
      interests: interests,
    );
  } on ApiException catch (e) {
    return UpdateUserInterestsFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return UpdateUserInterestsFailure(statusCode: -1, error: e);
  }
}

Future<UserReviewsResponse> fetchUserReviews(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/reviews/');
  final decoded = jsonDecode(response.body) as dynamic;
  if (decoded is Map<String, dynamic>) {
    return UserReviewsResponse.fromJson(decoded);
  }
  if (decoded is List) {
    return UserReviewsResponse.fromJson(<String, dynamic>{
      'count': decoded.length,
      'reviews': decoded,
    });
  }
  throw const FormatException('Unexpected reviews response format');
}

/// "Attended events" are represented by Sessions.
/// Uses GET /api/sessions/?user=<username>
Future<List<Session>> fetchUserSessions({required String username}) async {
  final response = await ApiClient.get(
    '/api/sessions/',
    queryParams: {'user': username},
  );
  final decoded = jsonDecode(response.body) as dynamic;
  final rawSessions = _extractSessionList(decoded);
  return rawSessions
      .whereType<Map<String, dynamic>>()
      .map(SessionDto.fromJson)
      .map((dto) => dto.toDomain())
      .toList();
}

List<dynamic> _extractSessionList(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    final dynamic raw =
        decoded['results'] ??
        decoded['sessions'] ??
        decoded['items'] ??
        decoded['data'];
    if (raw is List) return raw;
  }
  return const <dynamic>[];
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
        if (body['first_name'] != null) {
          return UpdateProfileValidationError(
            field: 'first_name',
            message: _extractErrorMessage(body['first_name']),
          );
        }
        if (body['last_name'] != null) {
          return UpdateProfileValidationError(
            field: 'last_name',
            message: _extractErrorMessage(body['last_name']),
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

/// DELETE /api/users/{id}/ — el backend retorna 204.
Future<DeleteAccountResult> deleteUserAccount(int userId) async {
  try {
    await ApiClient.delete('/api/users/$userId/', expectedStatusCode: 204);
    return DeleteAccountSuccess();
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return DeleteAccountUnauthorized();
    }
    return DeleteAccountFailure(statusCode: e.statusCode);
  } catch (_) {
    return DeleteAccountFailure(statusCode: -1);
  }
}

String _extractErrorMessage(dynamic value) {
  if (value is List && value.isNotEmpty) {
    return value.first.toString();
  }
  return value.toString();
}
