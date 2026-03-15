import 'package:agendat/core/services/events_response_parser.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:http/http.dart' as http;

class FiltersApiService {
  static const String _eventsPath = '/api/events/';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  Future<List<String>> fetchOptionsForCategory(String category) async {
    final uri = _buildEventsUri(date: DateTime.now());
    final events = await _fetchEventsForUri(
      uri,
      errorContext: 'Error obtenint opcions de filtre "$category"',
    );

    final values = <String>{};
    for (final event in events) {
      values.addAll(_extractValuesForCategory(event, category));
    }

    final sorted = values.toList()
      ..sort(
        (a, b) => EventTextUtils.normalizedForComparison(
          a,
        ).compareTo(EventTextUtils.normalizedForComparison(b)),
      );
    return sorted;
  }

  Future<List<Map<String, dynamic>>> fetchEventsByFilters({
    required Map<String, List<String>> selectedFilters,
    DateTime? date,
  }) async {
    final uri = _buildEventsUri(
      date: date ?? DateTime.now(),
      extraQueryParams: _buildFilterQueryParams(selectedFilters),
    );

    return _fetchEventsForUri(
      uri,
      errorContext: 'Error en l\'obtenció d\'esdeveniments filtrats',
    );
  }

  Uri _buildEventsUri({
    required DateTime date,
    DateTime? dateFrom,
    Map<String, String> extraQueryParams = const <String, String>{},
  }) {
    final effectiveDateFrom = dateFrom ?? _subtractMonths(date, 6);
    return Uri.parse('${getBaseUrl()}$_eventsPath').replace(
      queryParameters: <String, String>{
        'date': _formatDate(date),
        'date_from': _formatDate(effectiveDateFrom),
        ...extraQueryParams,
      },
    );
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  Future<List<Map<String, dynamic>>> _fetchEventsForUri(
    Uri uri, {
    required String errorContext,
  }) async {
    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        '$errorContext (HTTP ${response.statusCode}) per a $uri. '
        'Resposta: ${_responseSnippet(response.body)}',
      );
    }
    return EventsResponseParser.parseEventsBody(response.body);
  }

  String _responseSnippet(String body) {
    if (body.length <= 200) return body;
    return '${body.substring(0, 200)}...';
  }

  String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Map<String, String> _buildFilterQueryParams(
    Map<String, List<String>> selectedFilters,
  ) {
    final params = <String, String>{};
    for (final entry in selectedFilters.entries) {
      final apiKey = _normalizeFilterKey(entry.key);
      final values = _cleanFilterValues(entry.value);

      if (values.isEmpty) continue;
      params[apiKey] = values.join(',');
    }
    return params;
  }

  List<String> _cleanFilterValues(List<String> values) {
    return values
        .map(EventTextUtils.trimmedOrNull)
        .whereType<String>()
        .where((value) => !EventTextUtils.equalsIgnoringCase(value, 'tots'))
        .toList();
  }

  String _normalizeFilterKey(String key) {
    final normalized = EventTextUtils.normalizedForComparison(key);
    if (normalized == 'província') return 'provincia';
    if (normalized == 'categoria') return 'category';
    if (normalized == 'data') return 'date';
    return normalized;
  }

  List<String> _extractValuesForCategory(
    Map<String, dynamic> event,
    String category,
  ) {
    final normalized = _normalizeFilterKey(category);

    switch (normalized) {
      case 'categoria':
        final raw = event['categories'];
        if (raw is List) {
          return raw
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return EventTextUtils.trimmedOrNull(item['name']) ?? '';
                }
                return EventTextUtils.trimmedOrNull(item) ?? '';
              })
              .where((value) => value.isNotEmpty)
              .toList();
        }
        final value = EventTextUtils.trimmedOrNull(raw) ?? '';
        return value.isEmpty ? const [] : <String>[value];

      case 'data':
        final valueStart =
            EventTextUtils.trimmedOrNull(event['start_date']) ?? '';
        if (valueStart.isEmpty) return const [];
        return <String>[valueStart.split('T').first];

      case 'municipi':
        final value = EventTextUtils.trimmedOrNull(event['municipi']) ?? '';
        return value.isEmpty ? const [] : <String>[value];

      case 'comarca':
        final value = EventTextUtils.trimmedOrNull(event['comarca']) ?? '';
        return value.isEmpty ? const [] : <String>[value];

      case 'provincia':
        final value = EventTextUtils.trimmedOrNull(event['provincia']) ?? '';
        return value.isEmpty ? const [] : <String>[value];

      default:
        return const [];
    }
  }
}
