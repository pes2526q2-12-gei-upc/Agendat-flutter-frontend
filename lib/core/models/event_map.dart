import 'package:agendat/core/utils/event_text_utils.dart';

/// Lightweight event pin returned by `/api/events/map/`.
class EventMapPin {
  final String code;
  final double latitude;
  final double longitude;

  const EventMapPin({
    required this.code,
    required this.latitude,
    required this.longitude,
  });
}

/// Translated event preview returned by `/api/events/{code}/preview/`.
class EventPreview {
  final String code;
  final String? title;
  final DateTime? startDate;
  final DateTime? endDate;

  const EventPreview({
    required this.code,
    this.title,
    this.startDate,
    this.endDate,
  });

  String get displayTitle {
    final raw = title?.trim();
    return (raw == null || raw.isEmpty) ? 'Sense títol' : raw;
  }

  String get displayDateRange {
    final startDay = startDate == null
        ? null
        : DateTime(startDate!.year, startDate!.month, startDate!.day);
    final endDay = endDate == null
        ? null
        : DateTime(endDate!.year, endDate!.month, endDate!.day);
    final start = EventTextUtils.formatDisplayDate(startDate);
    final end = EventTextUtils.formatDisplayDate(endDate);
    if (start == null && end == null) return 'Per determinar';
    if (start != null && end != null && startDay == endDay) return start;
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start - Per determinar';
    return 'Per determinar - $end';
  }
}
