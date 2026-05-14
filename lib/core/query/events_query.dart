import 'package:flutter/foundation.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/models/event_map.dart';
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

  /// Fetches every event pin from `/api/events/map/` for the given filters.
  ///
  /// [date] defaults to today on the API side. [category] and [name] are
  /// forwarded only when non-empty.
  Future<List<EventMapPin>> getEventMapPins({
    DateTime? date,
    String? category,
    String? name,
    bool forceRefresh = false,
  }) {
    return _client.query<List<EventMapPin>>(
      key: _mapKey(date: date, category: category, name: name),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchEventMapPins(
          date: date,
          category: category,
          name: name,
        );
        return dtos
            .where(
              (dto) =>
                  dto.code.isNotEmpty &&
                  dto.latitude != null &&
                  dto.longitude != null,
            )
            .map(
              (dto) => EventMapPin(
                code: dto.code,
                latitude: dto.latitude!,
                longitude: dto.longitude!,
              ),
            )
            .toList();
      },
    );
  }

  /// Fetches the translated preview for [eventCode].
  Future<EventPreview> getEventPreview(
    String eventCode, {
    bool forceRefresh = false,
  }) {
    final code = eventCode.trim();
    return _client.query<EventPreview>(
      key: _previewKey(code),
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dto = await _api.fetchEventPreview(code);
        return EventPreview(
          code: code,
          title: dto.denomination,
          startDate: _parseDate(dto.startDate),
          endDate: _parseDate(dto.endDate),
        );
      },
    );
  }

  /// Invalidates every cached events query (lists + details).
  void invalidateAll() => _client.invalidatePrefix(_prefix);

  /// Invalidates only the cached list queries (every filter combination,
  /// including the per-page entries used by infinite scroll).
  void invalidateLists() => _client.invalidatePrefix('$_prefix:list');

  /// Invalidates every cached map-pins query (any date/category/name combo).
  void invalidateMapPins() => _client.invalidatePrefix('$_prefix:map');

  /// Invalidates the cached detail for a specific event code.
  void invalidateDetail(String eventCode) =>
      _client.invalidate(_detailKey(eventCode.trim()));

  /// Invalidates the cached preview for a specific event code.
  void invalidatePreview(String eventCode) =>
      _client.invalidate(_previewKey(eventCode.trim()));

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

  String _previewKey(String eventCode) => '$_prefix:preview:$eventCode';

  String _mapKey({DateTime? date, String? category, String? name}) {
    final dateKey = date == null ? '' : _formatDateKey(date);
    final categoryKey = category?.trim() ?? '';
    final nameKey = name?.trim() ?? '';
    return '$_prefix:map:$dateKey:$categoryKey:$nameKey';
  }

  static String _formatDateKey(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed?.toLocal();
  }

  bool _areSameFilters(EventFilters? a, EventFilters? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return mapEquals(a.toQueryParams(), b.toQueryParams());
  }
}
