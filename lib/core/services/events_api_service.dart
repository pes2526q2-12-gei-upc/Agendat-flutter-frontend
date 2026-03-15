import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/services/events_response_parser.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:http/http.dart' as http;

class EventsApiService {
  static const String _eventsPath = '/api/events/';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  Future<List<Map<String, dynamic>>> fetchEvents({
    DateTime? date,
    DateTime? dateFrom,
  }) async {
    final targetDate = date ?? DateTime.now();
    final targetDateFrom = dateFrom ?? _subtractMonths(targetDate, 6);

    final uri = Uri.parse('${getBaseUrl()}$_eventsPath').replace(
      queryParameters: {
        'date': _formatDate(targetDate),
        'date_from': _formatDate(targetDateFrom),
      },
    );

    return _fetchAndParse(uri);
  }

  Future<List<Map<String, dynamic>>> fetchFilteredEvents(
    EventFilters filters,
  ) async {
    final defaultFrom = _subtractMonths(DateTime.now(), 6);

    final queryParams = <String, String>{
      'date_from': _formatDate(filters.dateFrom ?? defaultFrom),
      ...filters.toQueryParams(),
    };

    final uri = Uri.parse('${getBaseUrl()}$_eventsPath').replace(
      queryParameters: queryParams,
    );

    return _fetchAndParse(uri);
  }

  Future<List<Map<String, dynamic>>> _fetchAndParse(Uri uri) async {
    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
        'Failed to load events (HTTP ${response.statusCode}) for $uri. '
        'Response: $snippet',
      );
    }

    return EventsResponseParser.parseEventsBody(response.body);
  }

  static DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;
    return DateTime(year, month, day);
  }

  static String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
