import 'package:agendat/core/services/events_response_parser.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:http/http.dart' as http;

class EventsApiService {
  static const String _eventsPath = '/api/events/';

  Future<List<Map<String, dynamic>>> fetchEvents({DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final formattedDate =
        '${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '${getBaseUrl()}$_eventsPath',
    ).replace(queryParameters: {'date': formattedDate});

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
        'Failed to load events (HTTP ${response.statusCode}) for $uri. Response: $snippet',
      );
    }

    return EventsResponseParser.parseEventsBody(response.body);
  }
}
