import 'package:agendat/core/api/sessions_api.dart';
import 'package:agendat/core/mappers/session_mapper.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/query_client.dart';

class SessionsQuery {
  static final SessionsQuery instance = SessionsQuery._();
  SessionsQuery._();

  static const Duration staleTime = Duration(minutes: 5);
  static const String _prefix = 'sessions';

  final SessionsApi _api = SessionsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<Session>> getSessions({bool forceRefresh = false}) {
    return _client.query<List<Session>>(
      key: _listKey,
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchSessions();
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<void> deleteSession(int sessionId) async {
    await _api.deleteSession(sessionId);
    invalidateAll();
  }

  /// Invalidates all cached sessions queries.
  void invalidateAll() => _client.invalidatePrefix(_prefix);

  String get _listKey => '$_prefix:list';
}
