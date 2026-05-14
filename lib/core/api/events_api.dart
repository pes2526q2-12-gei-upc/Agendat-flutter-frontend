import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/event_list_dto.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/services/events_response_parser.dart';

class EventsApi {
  static const String _path = '/api/events/';

  /// Mida de pàgina per defecte. El backend accepta fins a 50, però
  /// 20 manté la UI lleugera.
  static const int defaultPageSize = 20;

  /// Fetches the lightweight list of map pins from `/api/events/map/`.
  ///
  /// The endpoint returns every matching event without paginating. Only
  /// `date`, `category` and `name` are forwarded — the rest of `EventFilters`
  /// is irrelevant on the map.
  Future<List<EventMapPinDto>> fetchEventMapPins({
    DateTime? date,
    String? category,
    String? name,
  }) async {
    final params = <String, String>{
      'date': _formatDate(date ?? DateTime.now()),
    };
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (name != null && name.trim().isNotEmpty) {
      params['name'] = name.trim();
    }

    final response = await ApiClient.get('${_path}map/', queryParams: params);
    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      final rawResults = decoded['results'] ?? decoded['events'];
      if (rawResults is List) {
        return rawResults
            .whereType<Map<String, dynamic>>()
            .map(EventMapPinDto.fromJson)
            .toList();
      }
      return const <EventMapPinDto>[];
    }
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EventMapPinDto.fromJson)
          .toList();
    }
    throw const FormatException('Unexpected API response format');
  }

  /// Fetches the translated preview for a single event.
  Future<EventPreviewDto> fetchEventPreview(String eventCode) async {
    final code = eventCode.trim();
    if (code.isEmpty) {
      throw const FormatException(
        'El codi de l\'esdeveniment no pot ser buit.',
      );
    }
    final response = await ApiClient.get('$_path$code/preview/');
    final decoded = ApiClient.decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return EventPreviewDto.fromJson(decoded);
    }
    throw const FormatException('Unexpected API response format');
  }

  Future<EventExtended> fetchEventByCode(String eventCode) async {
    final code = eventCode.trim();
    if (code.isEmpty) {
      throw const FormatException(
        'El codi de l\'esdeveniment no pot ser buit.',
      );
    }
    final response = await ApiClient.get('$_path$code/');
    final decoded = ApiClient.decodeBody(response);
    final Map<String, dynamic> json = decoded is Map<String, dynamic>
        ? decoded
        : EventsResponseParser.parseSingleEventBody(response.body, code);
    return EventDto.fromJson(json).toExtendedDomain();
  }

  /// Fetches a single page from `/api/events/`.
  ///
  /// Use this for paginated UIs (infinite scroll). The first page should be
  /// requested with `offset: 0`; subsequent pages must pass `offset` equal to
  /// the amount of events already shown.
  Future<PaginatedEventsDto> fetchEventsPage({
    EventFilters? filters,
    int offset = 0,
    int limit = defaultPageSize,
  }) async {
    final params = _buildQueryParams(filters);
    params['limit'] = limit.toString();
    params['offset'] = offset.toString();

    final response = await ApiClient.get(_path, queryParams: params);
    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return PaginatedEventsDto.fromJson(decoded);
    }
    if (decoded is List) {
      // Older (non-paginated) responses arrived as a flat list. Treat them as
      // a single complete page so existing callers keep working.
      final results = decoded
          .whereType<Map<String, dynamic>>()
          .map(EventListDto.fromJson)
          .toList();
      return PaginatedEventsDto(
        count: results.length,
        next: null,
        previous: null,
        results: results,
      );
    }
    throw const FormatException('Unexpected API response format');
  }

  /// Fetches every event that matches [filters] by iterating the paginated
  /// endpoint until there are no more pages.
  ///
  /// Used by callers that genuinely need the full dataset. Prefer
  /// [fetchEventsPage] for list UIs.
  Future<List<EventListDto>> fetchEvents({EventFilters? filters}) async {
    final accumulated = <EventListDto>[];
    int offset = 0;
    while (true) {
      final page = await fetchEventsPage(
        filters: filters,
        offset: offset,
        limit: defaultPageSize,
      );
      accumulated.addAll(page.results);
      if (!page.hasNext || page.results.isEmpty) break;
      if (accumulated.length >= page.count) break;
      offset = accumulated.length;
    }
    return accumulated;
  }

  Map<String, String> _buildQueryParams(EventFilters? filters) {
    final now = DateTime.now();
    final defaultFrom = _subtractMonths(now, 6);
    final defaultTo = _addMonths(now, 6);

    final params = <String, String>{
      'date_from': _formatDate(filters?.dateFrom ?? defaultFrom),
      'date_to': _formatDate(filters?.dateTo ?? defaultTo),
    };

    if (filters != null) {
      final filterParams = filters.toQueryParams();
      // date range already set above (with fallback); override if explicit
      if (filters.dateFrom != null) {
        params['date_from'] = filterParams['date_from']!;
      }
      if (filters.dateTo != null) {
        params['date_to'] = filterParams['date_to']!;
      }
      filterParams.remove('date_from');
      filterParams.remove('date_to');
      params.addAll(filterParams);
    }

    return params;
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  static String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
