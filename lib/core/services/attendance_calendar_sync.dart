import 'package:agendat/core/services/google_calendar_service.dart';

enum AttendanceCalendarSyncResult { skipped, created, failed }

abstract class AttendanceCalendarClient {
  Future<String?> getAccessToken();

  Future<bool> createCalendarEvent({
    required String accessToken,
    required String eventTitle,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
  });
}

class GoogleAttendanceCalendarClient implements AttendanceCalendarClient {
  GoogleAttendanceCalendarClient([GoogleCalendarService? service])
    : _service = service ?? GoogleCalendarService();

  final GoogleCalendarService _service;

  @override
  Future<String?> getAccessToken() => _service.getAccessToken();

  @override
  Future<bool> createCalendarEvent({
    required String accessToken,
    required String eventTitle,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
  }) {
    return _service.createCalendarEvent(
      accessToken: accessToken,
      eventTitle: eventTitle,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      description: description,
    );
  }
}

Future<AttendanceCalendarSyncResult> syncAttendanceSessionToGoogleCalendar({
  required AttendanceCalendarClient calendarClient,
  required bool calendarSyncAllowed,
  required String eventTitle,
  required DateTime? startDateTime,
  DateTime? endDateTime,
  String? description,
}) async {
  if (!calendarSyncAllowed || startDateTime == null) {
    return AttendanceCalendarSyncResult.skipped;
  }

  final resolvedEndTime =
      (endDateTime != null && endDateTime.isAfter(startDateTime))
      ? endDateTime
      : startDateTime.add(const Duration(hours: 1));

  final accessToken = await calendarClient.getAccessToken();
  if (accessToken == null || accessToken.trim().isEmpty) {
    return AttendanceCalendarSyncResult.failed;
  }

  final created = await calendarClient.createCalendarEvent(
    accessToken: accessToken,
    eventTitle: eventTitle,
    startDateTime: startDateTime,
    endDateTime: resolvedEndTime,
    description: description,
  );

  return created
      ? AttendanceCalendarSyncResult.created
      : AttendanceCalendarSyncResult.failed;
}
