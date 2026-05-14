import 'package:flutter/foundation.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/query_client.dart';

/// Result of a single paginated request to `/api/events/`.
class PaginatedEvents {
  /// Total amount of events that match the current filters across all pages.
  final int count;

  /// `true` when there are more pages to fetch after this one.
  final bool hasMore;

  /// Events returned by this specific page.
  final List<Event> events;

  const PaginatedEvents({
    required this.count,
    required this.hasMore,
    required this.events,
  });
}

class EventsQuery {
  static final EventsQuery instance = EventsQuery._();
  EventsQuery._();

  static const Duration staleTime = Duration(minutes: 5);
  static const int defaultPageSize = EventsApi.defaultPageSize;
  static const String _prefix = 'events';

  final EventsApi _api = EventsApi();
  final QueryClient _client = QueryClient.instance;
  // Punt únic de veritat per al filtre compartit (Map + Visualize).
  final ValueNotifier<EventFilters?> _persistedFiltersNotifier =
      ValueNotifier<EventFilters?>(null);

  /// Llista d'events publicada per la pantalla home, perquè altres
  /// pantalles (com el mapa) la puguin reaprofitar sense fer crides
  /// addicionals a `/api/events/`.
  final ValueNotifier<List<Event>> _publishedEventsNotifier =
      ValueNotifier<List<Event>>(const <Event>[]);

  EventFilters? get persistedFilters => _persistedFiltersNotifier.value;
  ValueListenable<EventFilters?> get persistedFiltersListenable =>
      _persistedFiltersNotifier;

  ValueListenable<List<Event>> get publishedEvents => _publishedEventsNotifier;

  void setPersistedFilters(EventFilters filters) {
    // Si no canvia res, no disparem listeners perquè seria fer soroll.
    if (_areSameFilters(_persistedFiltersNotifier.value, filters)) return;
    // Aquí queda guardat el "filtre compartit" entre pantalles.
    _persistedFiltersNotifier.value = filters;
  }

  /// Publica la llista d'events actualment carregada per la home perquè
  /// altres pantalles hi tinguin accés. Es crida cada vegada que la home
  /// acaba de carregar (primera pàgina, més pàgines per scroll, etc.).
  void publishEvents(List<Event> events) {
    _publishedEventsNotifier.value = List<Event>.unmodifiable(events);
  }

  /// Returns every event for [filters] (iterating all pages under the hood).
  ///
  /// Intended for callers that need the full dataset. UIs that scroll
  /// should use [getEventsPage] instead.
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

  /// Fetches a single page of events.
  ///
  /// [offset] is the number of events to skip. For an infinite-scroll list the
  /// first call uses `offset: 0` and subsequent calls pass the amount of
  /// events already loaded.
  Future<PaginatedEvents> getEventsPage({
    EventFilters? filters,
    int offset = 0,
    int limit = defaultPageSize,
    bool forceRefresh = false,
  }) {
    return _client.query<PaginatedEvents>(
      key: _pageKey(filters, offset, limit),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dto = await _api.fetchEventsPage(
          filters: filters,
          offset: offset,
          limit: limit,
        );
        return PaginatedEvents(
          count: dto.count,
          hasMore: dto.hasNext,
          events: dto.results.map((d) => d.toDomain()).toList(),
        );
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

  /// Invalidates only the cached list queries (every filter combination,
  /// including the per-page entries used by infinite scroll).
  void invalidateLists() => _client.invalidatePrefix('$_prefix:list');

  /// Invalidates the cached detail for a specific event code.
  void invalidateDetail(String eventCode) =>
      _client.invalidate(_detailKey(eventCode.trim()));

  String _listKey(EventFilters? filters) {
    if (filters == null || filters.isEmpty) {
      return '$_prefix:list';
    }
    return '$_prefix:list:${_filterSignature(filters)}';
  }

  String _pageKey(EventFilters? filters, int offset, int limit) {
    final signature = (filters == null || filters.isEmpty)
        ? ''
        : _filterSignature(filters);
    return '$_prefix:list:page:$offset:$limit:$signature';
  }

  String _filterSignature(EventFilters filters) {
    final params =
        filters
            .toQueryParams()
            .entries
            .map((e) => '${e.key}=${e.value}')
            .toList()
          ..sort();
    return params.join('&');
  }

  String _detailKey(String eventCode) => '$_prefix:detail:$eventCode';

  bool _areSameFilters(EventFilters? a, EventFilters? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return mapEquals(a.toQueryParams(), b.toQueryParams());
  }
}
