import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/query_client.dart';

class EventsQuery {
  static final EventsQuery instance = EventsQuery._();
  EventsQuery._();

  static const Duration staleTime = Duration(minutes: 5);
  static const String _prefix = 'events';

  final EventsApi _api = EventsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<Event>> getEvents({
    EventFilters? filters,
    bool forceRefresh = false,
  }) {
    return _client.query<List<Event>>(
      key: _listKey(filters),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchEvents(filters: filters);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<EventExtended> getEventByCode(
    String eventCode, {
    bool forceRefresh = false,
  }) {
    final code = eventCode.trim();
    return _client.query<EventExtended>(
      key: _detailKey(code),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () => _api.fetchEventByCode(code),
    );
  }

  /// Invalidates every cached events query (lists + details).
  void invalidateAll() => _client.invalidatePrefix(_prefix);

  /// Invalidates only the cached list queries (every filter combination).
  void invalidateLists() => _client.invalidatePrefix('$_prefix:list');

  /// Invalidates the cached detail for a specific event code.
  void invalidateDetail(String eventCode) =>
      _client.invalidate(_detailKey(eventCode.trim()));

  String _listKey(EventFilters? filters) {
    if (filters == null || filters.isEmpty) return '$_prefix:list';
    final params =
        filters
            .toQueryParams()
            .entries
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    return '$_prefix:list:${params.join('&')}';
  }

  String _detailKey(String eventCode) => '$_prefix:detail:$eventCode';
}
