import 'package:agendat/core/utils/event_text_utils.dart';

class Event {
  final String code;
  final String title;
  final String? subtitle;
  final bool free;
  final List<String> categories;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? latitude;
  final double? longitude;

  const Event({
    required this.code,
    required this.title,
    this.subtitle,
    this.free = false,
    this.categories = const [],
    this.provincia,
    this.comarca,
    this.municipi,
    this.startDate,
    this.endDate,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  // ── Display helpers ──────────────────────────────────────────────

  String get location {
    final parts = [
      EventTextUtils.labelOrNull(municipi),
      EventTextUtils.labelOrNull(provincia),
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Per determinar' : parts.join(', ');
  }

  String get displayDateRange {
    final start = EventTextUtils.formatDisplayDate(startDate);
    final end = EventTextUtils.formatDisplayDate(endDate);
    if (start == null && end == null) return 'Per determinar';
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start - Per determinar';
    return 'Per determinar - $end';
  }

  String get displayCategory {
    return EventTextUtils.categoriesToCapitalizedString(categories) ?? 'General';
  }

  String get displaySubtitle {
    final raw = subtitle?.trim();
    return (raw == null || raw.isEmpty) ? 'Sense descripció' : raw;
  }

}

class EventExtended extends Event {
  final String? description;
  final String? url_activity;
  final String? url_ticket;
  final String? schedule;
  final String? modality;
  final String? urls;
  final String? images;
  final String? videos;
  final String? documents;
  final String? address;
  final String? email;
  final String? locality;
  final String? url_locality;
  final String? telephone_locality;

  const EventExtended({
    required super.code,
    required super.title,
    super.subtitle,
    super.free = false,
    super.categories = const [],
    super.provincia,
    super.comarca,
    super.municipi,
    super.startDate,
    super.endDate,
    super.latitude,
    super.longitude,
    this.description,
    this.url_activity,
    this.url_ticket,
    this.schedule,
    this.modality,
    this.urls,
    this.images,
    this.videos,
    this.documents,
    this.address,
    this.email,
    this.locality,
    this.url_locality,
    this.telephone_locality,
  });

  String get displayUrl => displayUrlUri?.toString() ?? '-';

  bool get hasDisplayUrl => displayUrlUri != null;

  Uri? get displayUrlUri {
    final raw = EventTextUtils.rawStringOrNull(url_locality) ??
        EventTextUtils.rawStringOrNull(url_activity) ??
        EventTextUtils.rawStringOrNull(url_ticket) ??
        EventTextUtils.rawStringOrNull(urls);

    if (raw == null) return null;

    final hasScheme = raw.startsWith('http://') || raw.startsWith('https://');
    final normalized = hasScheme ? raw : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

}

typedef EventExpanded = EventExtended;
