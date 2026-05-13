import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/event_list_dto.dart';
import 'package:agendat/core/mappers/event_mapper.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/services/events_response_parser.dart';

class EventsApi {
  static const String _path = '/api/events/';

  /// Default page size when the backend returns the original Catalan content.
  ///
  /// The backend accepts up to 50, but we stick to 20 to keep the UI snappy.
  static const int defaultPageSize = 20;

  /// Page size used when the backend has to translate events.
  ///
  /// We have a hard limit on translation API characters, so when the user
  /// requests another language we ask for fewer events per call.
  static const int translatedPageSize = 3;

  /// Returns the page size to use for [lang]: small when translation kicks in,
  /// the regular size otherwise.
  static int pageSizeForLang(String? lang) {
    final normalized = (lang ?? '').trim().toUpperCase();
    if (normalized.isEmpty || normalized == AppLanguage.defaultCode) {
      return defaultPageSize;
    }
    return translatedPageSize;
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
  ///
  /// When [lang] is provided and is not [AppLanguage.defaultCode], the
  /// backend will translate the event content into that language. Callers
  /// should pair non-Catalan requests with a smaller [limit] (see
  /// [translatedPageSize]).
  Future<PaginatedEventsDto> fetchEventsPage({
    EventFilters? filters,
    int offset = 0,
    int limit = defaultPageSize,
    String? lang,
  }) async {
    final params = _buildQueryParams(filters);
    params['limit'] = limit.toString();
    params['offset'] = offset.toString();
    final normalizedLang = _normalizeLang(lang);
    if (normalizedLang != null) {
      params['lang'] = normalizedLang;
    }

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
  /// Used by callers that genuinely need the full dataset (e.g. the map view
  /// to place every marker). Prefer [fetchEventsPage] for list UIs.
  ///
  /// When [lang] is non-Catalan the per-call page size is reduced to
  /// [translatedPageSize] to respect the translation budget.
  Future<List<EventListDto>> fetchEvents({
    EventFilters? filters,
    String? lang,
  }) async {
    final pageSize = pageSizeForLang(lang);
    final accumulated = <EventListDto>[];
    int offset = 0;
    while (true) {
      final page = await fetchEventsPage(
        filters: filters,
        offset: offset,
        limit: pageSize,
        lang: lang,
      );
      accumulated.addAll(page.results);
      if (!page.hasNext || page.results.isEmpty) break;
      if (accumulated.length >= page.count) break;
      offset = accumulated.length;
    }
    return accumulated;
  }

  static String? _normalizeLang(String? lang) {
    if (lang == null) return null;
    final upper = lang.trim().toUpperCase();
    if (upper.isEmpty) return null;
    if (!AppLanguage.supported.contains(upper)) return null;
    // Catalan is the backend default — no need to send the param.
    if (upper == AppLanguage.defaultCode) return null;
    return upper;
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
