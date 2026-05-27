import 'package:agendat/core/services/attendance_calendar_sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('syncAttendanceSessionToGoogleCalendar', () {
    test('skips when calendar sync is disabled', () async {
      final client = _FakeCalendarClient(accessToken: 'token');

      final result = await syncAttendanceSessionToGoogleCalendar(
        calendarClient: client,
        calendarSyncAllowed: false,
        eventTitle: 'Event',
        startDateTime: DateTime.utc(2026, 6, 1, 10),
        endDateTime: DateTime.utc(2026, 6, 1, 11),
      );

      expect(result, AttendanceCalendarSyncResult.skipped);
      expect(client.tokenRequests, 0);
      expect(client.createdRequests, isEmpty);
    });

    test('creates a calendar event when enabled', () async {
      final client = _FakeCalendarClient(accessToken: 'token');
      final start = DateTime.utc(2026, 6, 1, 10);
      final end = DateTime.utc(2026, 6, 1, 12);

      final result = await syncAttendanceSessionToGoogleCalendar(
        calendarClient: client,
        calendarSyncAllowed: true,
        eventTitle: 'Concert',
        startDateTime: start,
        endDateTime: end,
        description: 'From Agenda',
      );

      expect(result, AttendanceCalendarSyncResult.created);
      expect(client.tokenRequests, 1);
      expect(client.createdRequests, hasLength(1));
      expect(client.createdRequests.single.eventTitle, 'Concert');
      expect(client.createdRequests.single.startDateTime, start);
      expect(client.createdRequests.single.endDateTime, end);
      expect(client.createdRequests.single.description, 'From Agenda');
    });

    test('defaults end time to one hour after start when missing', () async {
      final client = _FakeCalendarClient(accessToken: 'token');
      final start = DateTime.utc(2026, 6, 1, 10);

      final result = await syncAttendanceSessionToGoogleCalendar(
        calendarClient: client,
        calendarSyncAllowed: true,
        eventTitle: 'Concert',
        startDateTime: start,
      );

      expect(result, AttendanceCalendarSyncResult.created);
      expect(
        client.createdRequests.single.endDateTime,
        start.add(const Duration(hours: 1)),
      );
    });
  });
}

class _FakeCalendarClient implements AttendanceCalendarClient {
  _FakeCalendarClient({required this.accessToken});

  final String? accessToken;
  int tokenRequests = 0;
  final List<_CreatedCalendarEvent> createdRequests = [];

  @override
  Future<String?> getAccessToken() async {
    tokenRequests += 1;
    return accessToken;
  }

  @override
  Future<bool> createCalendarEvent({
    required String accessToken,
    required String eventTitle,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
  }) async {
    createdRequests.add(
      _CreatedCalendarEvent(
        accessToken: accessToken,
        eventTitle: eventTitle,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        description: description,
      ),
    );
    return true;
  }
}

class _CreatedCalendarEvent {
  const _CreatedCalendarEvent({
    required this.accessToken,
    required this.eventTitle,
    required this.startDateTime,
    required this.endDateTime,
    required this.description,
  });

  final String accessToken;
  final String eventTitle;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
}
