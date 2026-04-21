import 'dart:convert';

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

/// Crida GET /api/users/?search=<query> per cercar usuaris pel seu nom.
///
/// El backend (DRF) retorna una llista (o un objecte amb `results`) amb
/// les dades bàsiques dels usuaris que coincideixen.
Future<SearchUsersResult> searchUsers(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return SearchUsersSuccess(users: const []);
  }

  try {
    final response = await ApiClient.get(
      '/api/users/',
      queryParams: {'search': trimmed},
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
