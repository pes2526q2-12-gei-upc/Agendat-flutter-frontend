import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/query_client.dart';

class EventsQuery {
  static const Duration staleTime = Duration(minutes: 5);
  static const String _prefix = 'events';

  final EventsApi _api = EventsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<Event>> getEvents({EventFilters? filters}) {
    final key = _buildKey(filters);
    return _client.query<List<Event>>(
      key: key,
      staleTime: staleTime,
      queryFn: () async {
        final dtos = await _api.fetchEvents(filters: filters);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  void invalidate() => _client.invalidatePrefix(_prefix);

  String _buildKey(EventFilters? filters) {
    if (filters == null || filters.isEmpty) return _prefix;
    final params = filters.toQueryParams().entries
        .map((e) => '${e.key}=${e.value}')
        .toList()
      ..sort();
    return '$_prefix:${params.join('&')}';
  }
}
