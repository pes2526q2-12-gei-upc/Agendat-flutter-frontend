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

  static Map<String, dynamic> parseSingleEventBody(
    String body,
    String eventCode,
  ) {
    final decoded = jsonDecode(body);

    if (decoded is Map<String, dynamic>) {
      final nestedEvent = decoded['event'];
      if (nestedEvent is Map<String, dynamic>) {
        return nestedEvent;
      }

      final nestedEvents = decoded['events'];
      if (nestedEvents is List) {
        return pickEventByCode(nestedEvents, eventCode);
      }

      final nestedResults = decoded['results'];
      if (nestedResults is List) {
        return pickEventByCode(nestedResults, eventCode);
      }

      return decoded;
    }

    if (decoded is List) {
      return pickEventByCode(decoded, eventCode);
    }

    throw const FormatException(
      'Format de resposta inesperat per al detall d\'esdeveniment.',
    );
  }

  static Map<String, dynamic> pickEventByCode(
    List<dynamic> events,
    String eventCode,
  ) {
    final entries = events.whereType<Map<String, dynamic>>().toList();
    if (entries.isEmpty) {
      throw const FormatException(
        'La resposta de detall no conté esdeveniments.',
      );
    }

    for (final event in entries) {
      final code = (event['code'] ?? '').toString().trim();
      if (code == eventCode) {
        return event;
      }
    }

    return entries.first;
  }
}
