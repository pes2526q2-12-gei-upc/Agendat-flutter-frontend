import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Estat de la relació d'amistat del meu usuari amb un altre usuari.
enum FriendshipStatus {
  /// No són amics i no hi ha cap sol·licitud pendent.
  none,

  /// Jo he enviat una sol·licitud a l'altre usuari i està pendent.
  requestSent,

  /// L'altre usuari m'ha enviat una sol·licitud que jo encara no he respost.
  requestReceived,

  /// Ja som amics.
  friends,
}

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

Future<FriendActionResult> _postFriendAction(String path) async {
  try {
    await ApiClient.postJson(
      path,
      body: const <String, dynamic>{},
      acceptedStatusCodes: const {200, 201, 202, 204},
    );
    return FriendActionSuccess();
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return FriendActionUnauthorized();
    }
    return FriendActionFailure(
      statusCode: e.statusCode,
      message: _extractErrorMessage(e.body),
      error: e,
    );
  } catch (e) {
    return FriendActionFailure(statusCode: -1, error: e);
  }
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

/// Resultat de la consulta de l'estat d'amistat entre el meu usuari i un altre.
sealed class FriendshipStatusResult {}

class FriendshipStatusSuccess extends FriendshipStatusResult {
  FriendshipStatusSuccess({required this.status});
  final FriendshipStatus status;
}

class FriendshipStatusUnauthorized extends FriendshipStatusResult {}

class FriendshipStatusFailure extends FriendshipStatusResult {
  FriendshipStatusFailure({required this.statusCode, this.error});
  final int statusCode;
  final Object? error;
}

/// Determina la relació d'amistat entre `myUserId` i `otherUserId` combinant
/// les dades dels endpoints de llista d'amics i de sol·licituds pendents.
Future<FriendshipStatusResult> fetchFriendshipStatus({
  required int myUserId,
  required int otherUserId,
}) async {
  if (myUserId == otherUserId) {
    return FriendshipStatusSuccess(status: FriendshipStatus.none);
  }

  try {
    final friendsFuture = ApiClient.get('/api/users/$myUserId/friends/');
    final requestsFuture = ApiClient.get(
      '/api/users/$myUserId/friend-requests/',
    );

    final friendsResp = await friendsFuture;
    final friendIds = _extractUserIds(jsonDecode(friendsResp.body));
    if (friendIds.contains(otherUserId)) {
      return FriendshipStatusSuccess(status: FriendshipStatus.friends);
    }

    final requestsResp = await requestsFuture;
    final (sent, received) = _extractRequestDirections(
      jsonDecode(requestsResp.body),
      myUserId: myUserId,
    );

    if (received.contains(otherUserId)) {
      return FriendshipStatusSuccess(status: FriendshipStatus.requestReceived);
    }
    if (sent.contains(otherUserId)) {
      return FriendshipStatusSuccess(status: FriendshipStatus.requestSent);
    }

    return FriendshipStatusSuccess(status: FriendshipStatus.none);
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return FriendshipStatusUnauthorized();
    }
    return FriendshipStatusFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return FriendshipStatusFailure(statusCode: -1, error: e);
  }
}

/// Accepta diferents formats (llista directa o `{results: [...]}`) i retorna
/// els `id` dels usuaris que hi figuren.
Set<int> _extractUserIds(dynamic decoded) {
  final list = _unwrapList(decoded);
  final ids = <int>{};
  for (final item in list) {
    if (item is Map<String, dynamic>) {
      final id = _readInt(item['id']) ?? _readInt(item['user_id']);
      if (id != null) ids.add(id);
    } else {
      final id = _readInt(item);
      if (id != null) ids.add(id);
    }
  }
  return ids;
}

/// Extreu, a partir d'una llista de sol·licituds pendents, dos conjunts:
/// els usuaris a qui jo he enviat una sol·licitud i els que me n'han enviat
/// una a mi. Intenta ser tolerant amb diferents formats de resposta.
(Set<int> sent, Set<int> received) _extractRequestDirections(
  dynamic decoded, {
  required int myUserId,
}) {
  final list = _unwrapList(decoded);
  final sent = <int>{};
  final received = <int>{};

  for (final raw in list) {
    if (raw is! Map<String, dynamic>) continue;

    final fromId = _readUserIdField(raw, const [
      'from_user',
      'from',
      'sender',
      'requester',
      'from_user_id',
    ]);
    final toId = _readUserIdField(raw, const [
      'to_user',
      'to',
      'receiver',
      'recipient',
      'to_user_id',
    ]);

    if (fromId != null && toId != null) {
      if (fromId == myUserId && toId != myUserId) {
        sent.add(toId);
      } else if (toId == myUserId && fromId != myUserId) {
        received.add(fromId);
      }
      continue;
    }

    // Fallback: alguns backends retornen només l'altra part, o un camp
    // `direction`/`type` indicant si és sent/received.
    final direction = (raw['direction'] ?? raw['type'] ?? raw['status'])
        ?.toString();
    final otherId =
        _readUserIdField(raw, const ['user', 'user_id', 'id']) ??
        fromId ??
        toId;
    if (otherId == null || otherId == myUserId) continue;

    if (direction != null) {
      final d = direction.toLowerCase();
      if (d.contains('sent') || d.contains('outgoing')) {
        sent.add(otherId);
        continue;
      }
      if (d.contains('received') ||
          d.contains('incoming') ||
          d.contains('pending')) {
        received.add(otherId);
        continue;
      }
    }

    // Assumpció conservadora: si no podem determinar la direcció, tractem
    // l'element com una sol·licitud rebuda (l'endpoint, sense més context,
    // típicament llista les pendents d'acceptar per part meva).
    received.add(otherId);
  }

  return (sent, received);
}

List<dynamic> _unwrapList(dynamic decoded) {
  if (decoded is List) return decoded;
  if (decoded is Map<String, dynamic>) {
    for (final key in const ['results', 'friends', 'requests', 'data']) {
      final value = decoded[key];
      if (value is List) return value;
    }
  }
  return const [];
}

int? _readUserIdField(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (!map.containsKey(key)) continue;
    final value = map[key];
    if (value is Map<String, dynamic>) {
      final id = _readInt(value['id']) ?? _readInt(value['user_id']);
      if (id != null) return id;
    } else {
      final id = _readInt(value);
      if (id != null) return id;
    }
  }
  return null;
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
