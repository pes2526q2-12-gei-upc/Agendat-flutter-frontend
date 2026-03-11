import 'package:agendat/core/services/events_response_parser.dart';
import 'package:agendat/core/services/baseURL_api.dart';
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
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
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
    Map<String, String> extraQueryParams = const <String, String>{},
  }) {
    return Uri.parse('${getBaseUrl()}$_eventsPath').replace(
      queryParameters: <String, String>{
        'date': _formatDate(date),
        ...extraQueryParams,
      },
    );
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
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty && value.toLowerCase() != "Tots")
        .toList();
  }

  String _normalizeFilterKey(String key) {
    final normalized = key.toLowerCase().trim();
    if (normalized == 'província') return 'provincia';
    return normalized;
  }

  List<String> _extractValuesForCategory(
    Map<String, dynamic> event,
    String category,
  ) {
    final normalized = category.toLowerCase().trim();

    switch (normalized) {
      case 'categoria':
        final raw = event['categories'] ?? event['category'];
        if (raw is List) {
          return raw
              .map((item) {
                if (item is Map<String, dynamic>) {
                  return (item['name'] ?? '').toString().trim();
                }
                return item.toString().trim();
              })
              .where((value) => value.isNotEmpty)
              .toList();
        }
        final value = raw?.toString().trim() ?? '';
        return value.isEmpty ? const [] : <String>[value];

      case 'data':
        final value = (event['start_date'] ?? event['startDate'] ?? '')
            .toString()
            .trim();
        if (value.isEmpty) return const [];
        return <String>[value.split('T').first];

      case 'ciutat':
        final value =
            (event['ciutat'] ?? event['city'] ?? event['municipi'] ?? '')
                .toString()
                .trim();
        return value.isEmpty ? const [] : <String>[value];

      case 'municipi':
        final value = (event['municipi'] ?? '').toString().trim();
        return value.isEmpty ? const [] : <String>[value];

      case 'comarca':
        final value = (event['comarca'] ?? '').toString().trim();
        return value.isEmpty ? const [] : <String>[value];

      case 'provincia':
        final value = (event['provincia'] ?? event['província'] ?? '')
            .toString()
            .trim();
        return value.isEmpty ? const [] : <String>[value];

      default:
        return const [];
    }
  }
}
