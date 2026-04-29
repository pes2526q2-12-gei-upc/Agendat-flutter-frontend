import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

sealed class SearchUsersResult {}

class SearchUsersSuccess extends SearchUsersResult {
  SearchUsersSuccess({required this.users});
  final List<UserSummary> users;
}

class SearchUsersUnauthorized extends SearchUsersResult {}

class SearchUsersFailure extends SearchUsersResult {
  SearchUsersFailure({required this.statusCode, this.error});
  final int statusCode;
  final Object? error;
}

/// Crida GET /api/users/?q=<query> per cercar usuaris pel seu nom.
///
/// El backend filtra per coincidències parcials (case-insensitive) sobre
/// `username`, `first_name` i `last_name`, i retorna una llista (o un
/// objecte amb `results`) amb les dades bàsiques dels usuaris trobats.
Future<SearchUsersResult> searchUsers(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return SearchUsersSuccess(users: const []);
  }

  try {
    final response = await ApiClient.get(
      '/api/users/',
      queryParams: {'q': trimmed},
    );
    final decoded = jsonDecode(response.body);

    List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      rawList = decoded['results'] as List<dynamic>;
    } else {
      rawList = const [];
    }

    final users = rawList
        .whereType<Map<String, dynamic>>()
        .map(UserSummary.fromJson)
        .toList();

    final lowered = trimmed.toLowerCase();
    final filtered = users.where((u) {
      final username = u.username.toLowerCase();
      final fullName = u.displayName.toLowerCase();
      return username.contains(lowered) || fullName.contains(lowered);
    }).toList();

    filtered.sort((a, b) {
      final aUser = a.username.toLowerCase();
      final bUser = b.username.toLowerCase();
      final aStarts = aUser.startsWith(lowered);
      final bStarts = bUser.startsWith(lowered);
      if (aStarts && !bStarts) return -1;
      if (!aStarts && bStarts) return 1;
      return aUser.compareTo(bUser);
    });

    return SearchUsersSuccess(users: filtered);
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return SearchUsersUnauthorized();
    }
    return SearchUsersFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return SearchUsersFailure(statusCode: -1, error: e);
  }
}

// ---------------------------------------------------------------------------
// Friendship API
// ---------------------------------------------------------------------------

sealed class FriendActionResult {}

class FriendActionSuccess extends FriendActionResult {}

class FriendActionUnauthorized extends FriendActionResult {}

class FriendActionUserNotFound extends FriendActionResult {}

class FriendActionConflict extends FriendActionResult {
  FriendActionConflict({this.message});
  final String? message;
}

class FriendActionFailure extends FriendActionResult {
  FriendActionFailure({required this.statusCode, this.message, this.error});
  final int statusCode;
  final String? message;
  final Object? error;
}

/// POST /api/users/{id}/friend-request/
Future<FriendActionResult> sendFriendRequest(int userId) =>
    _postFriendAction('/api/users/$userId/friend-request/');

/// POST /api/users/{id}/cancel-friend-request/
Future<FriendActionResult> cancelFriendRequest(int userId) =>
    _postFriendAction('/api/users/$userId/cancel-friend-request/');

/// POST /api/users/{id}/accept-friend-request/
Future<FriendActionResult> acceptFriendRequest(int userId) =>
    _postFriendAction('/api/users/$userId/accept-friend-request/');

/// POST /api/users/{id}/reject-friend-request/
Future<FriendActionResult> rejectFriendRequest(int userId) =>
    _postFriendAction('/api/users/$userId/reject-friend-request/');

/// DELETE /api/users/{id}/unfriend/
Future<FriendActionResult> unfriendUser(int userId) =>
    _deleteFriendAction('/api/users/$userId/unfriend/');

Future<FriendActionResult> _postFriendAction(String path) async {
  try {
    await ApiClient.postJson(
      path,
      body: const <String, dynamic>{},
      acceptedStatusCodes: const {200, 201, 202, 204},
    );
    return FriendActionSuccess();
  } on ApiException catch (e) {
    return _mapFriendActionApiException(e);
  } catch (e) {
    return FriendActionFailure(statusCode: -1, error: e);
  }
}

Future<FriendActionResult> _deleteFriendAction(String path) async {
  try {
    await ApiClient.delete(path, acceptedStatusCodes: const {200, 202, 204});
    return FriendActionSuccess();
  } on ApiException catch (e) {
    return _mapFriendActionApiException(e);
  } catch (e) {
    return FriendActionFailure(statusCode: -1, error: e);
  }
}

FriendActionResult _mapFriendActionApiException(ApiException e) {
  if (e.statusCode == 401 || e.statusCode == 403) {
    return FriendActionUnauthorized();
  }
  if (e.statusCode == 404) {
    return FriendActionUserNotFound();
  }
  if (e.statusCode == 409) {
    return FriendActionConflict(message: _extractErrorMessage(e.body));
  }
  return FriendActionFailure(
    statusCode: e.statusCode,
    message: _extractErrorMessage(e.body),
    error: e,
  );
}

// ---------------------------------------------------------------------------
// Friend requests / friends listing
// ---------------------------------------------------------------------------

/// Sol·licitud d'amistat pendent, endpoint `GET /api/users/{id}/friend-requests/`.
///
/// `counterpart` arriba com un objecte d'usuari complet (no com un string,
/// tot i que el Swagger l'etiqueti genèricament). Representa "l'altre"
/// usuari: el destinatari dins de `sent[]` i el remitent dins de `received[]`.
class PendingFriendRequest {
  const PendingFriendRequest({
    required this.id,
    required this.status,
    this.counterpart,
    this.requestedBy,
    this.blockedBy,
    this.createdAt,
  });

  final int id;
  final String status;
  final UserSummary? counterpart;
  final UserSummary? requestedBy;
  final UserSummary? blockedBy;
  final DateTime? createdAt;

  factory PendingFriendRequest.fromJson(Map<String, dynamic> json) {
    UserSummary? parseUser(dynamic raw) {
      if (raw is Map<String, dynamic>) return UserSummary.fromJson(raw);
      return null;
    }

    DateTime? parseDate(dynamic raw) {
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    }

    return PendingFriendRequest(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as String?) ?? 'pending',
      counterpart: parseUser(json['counterpart']),
      requestedBy: parseUser(json['requested_by']),
      blockedBy: parseUser(json['blocked_by']),
      createdAt: parseDate(json['created_at']),
    );
  }
}

/// Resposta de `GET /api/users/{id}/friend-requests/`.
class FriendRequestsData {
  const FriendRequestsData({required this.sent, required this.received});

  final List<PendingFriendRequest> sent;
  final List<PendingFriendRequest> received;

  static const FriendRequestsData empty = FriendRequestsData(
    sent: [],
    received: [],
  );

  factory FriendRequestsData.fromJson(Map<String, dynamic> json) {
    List<PendingFriendRequest> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PendingFriendRequest.fromJson)
          .toList();
    }

    return FriendRequestsData(
      sent: parseList(json['sent']),
      received: parseList(json['received']),
    );
  }
}

/// GET /api/users/{userId}/friend-requests/
Future<FriendRequestsData> fetchFriendRequests(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/friend-requests/');
  if (kDebugMode) {
    debugPrint('[social] GET /friend-requests/ for $userId → ${response.body}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is Map<String, dynamic>) {
    return FriendRequestsData.fromJson(decoded);
  }
  return FriendRequestsData.empty;
}

/// GET /api/users/{userId}/friends/
Future<List<UserSummary>> fetchFriends(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/friends/');
  if (kDebugMode) {
    debugPrint('[social] GET /friends/ for $userId → ${response.body}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is List) {
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(UserSummary.fromJson)
        .toList();
  }
  if (decoded is Map<String, dynamic> && decoded['results'] is List) {
    return (decoded['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(UserSummary.fromJson)
        .toList();
  }
  return const [];
}

// ---------------------------------------------------------------------------
// Block / Unblock API
// ---------------------------------------------------------------------------

/// Resultat d'una acció de bloquejar/desbloquejar un usuari.
sealed class BlockActionResult {}

class BlockActionSuccess extends BlockActionResult {}

/// L'usuari no està autenticat o el token ja no és vàlid.
class BlockActionUnauthorized extends BlockActionResult {}

/// El perfil destinatari no existeix (HTTP 404). El backend interpreta el
/// destinatari com a invàlid (eliminat o mai existent).
class BlockActionUserNotFound extends BlockActionResult {}

/// El bloqueig (o desbloqueig) ja estava aplicat al backend. Útil per mantenir
/// la UI coherent en cas de doble click o desincronització de la caché.
class BlockActionConflict extends BlockActionResult {
  BlockActionConflict({this.message});
  final String? message;
}

class BlockActionFailure extends BlockActionResult {
  BlockActionFailure({required this.statusCode, this.message, this.error});
  final int statusCode;
  final String? message;
  final Object? error;
}

/// POST /api/users/{id}/block/ — bloqueja un usuari. El backend és l'encarregat
/// d'eliminar la relació d'amistat (si existia) i les sol·licituds pendents.
Future<BlockActionResult> blockUser(int userId) =>
    _postBlockAction('/api/users/$userId/block/');

/// POST /api/users/{id}/unblock/ — desbloqueja un usuari prèviament bloquejat.
/// No restableix l'amistat: si l'usuari vol tornar a ser amic, ha de tornar a
/// passar pel flux de sol·licitud.
Future<BlockActionResult> unblockUser(int userId) =>
    _postBlockAction('/api/users/$userId/unblock/');

Future<BlockActionResult> _postBlockAction(String path) async {
  try {
    await ApiClient.postJson(
      path,
      body: const <String, dynamic>{},
      acceptedStatusCodes: const {200, 201, 202, 204},
    );
    return BlockActionSuccess();
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return BlockActionUnauthorized();
    }
    if (e.statusCode == 404) {
      return BlockActionUserNotFound();
    }
    if (e.statusCode == 409) {
      return BlockActionConflict(message: _extractErrorMessage(e.body));
    }
    return BlockActionFailure(
      statusCode: e.statusCode,
      message: _extractErrorMessage(e.body),
      error: e,
    );
  } catch (e) {
    return BlockActionFailure(statusCode: -1, error: e);
  }
}

/// GET /api/users/{userId}/blocked-users/ — llista d'usuaris que jo he
/// bloquejat.
/// Es fa servir per derivar si un perfil concret està bloquejat (mentre el
/// backend no exposi `friendship_status` a `GET /api/users/{id}/`).
Future<List<UserSummary>> fetchBlockedUsers(int userId) async {
  final response = await ApiClient.get('/api/users/$userId/blocked-users/');
  if (kDebugMode) {
    debugPrint('[social] GET /blocked-users/ for $userId → ${response.body}');
  }
  final decoded = jsonDecode(response.body);
  if (decoded is List) {
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(UserSummary.fromJson)
        .toList();
  }
  if (decoded is Map<String, dynamic> && decoded['results'] is List) {
    return (decoded['results'] as List)
        .whereType<Map<String, dynamic>>()
        .map(UserSummary.fromJson)
        .toList();
  }
  return const [];
}

String? _extractErrorMessage(String body) {
  if (body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['detail', 'message', 'error']) {
        final value = decoded[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
    }
  } catch (_) {
    // Not valid JSON, ignore.
  }
  return null;
}
