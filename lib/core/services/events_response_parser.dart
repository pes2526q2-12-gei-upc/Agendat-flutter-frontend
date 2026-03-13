import 'dart:convert';

class EventsResponseParser {
  const EventsResponseParser._();

  static List<Map<String, dynamic>> parseEventsBody(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }

    throw const FormatException('Format de resposta inesperat per a /events');
  }
}
