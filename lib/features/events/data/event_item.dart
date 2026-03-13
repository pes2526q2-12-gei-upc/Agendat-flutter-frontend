import 'package:agendat/core/utils/event_text_utils.dart';

class EventItem {
  final String code;
  final String title;
  final String? subtitle;
  final String? description;
  final String? url_activity;
  final String? url_ticket;
  final String? schedule;
  final bool free;
  final String? modality;
  final String? urls;
  final String? images;
  final String? videos;
  final String? documents;
  final String? address;
  final String? email;
  final String? locality;
  final String? url_locality;
  final String? startDate;
  final String? endDate;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final String? categories;

  const EventItem({
    required this.code,
    required this.title,
    this.subtitle,
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
    this.startDate,
    this.endDate,
    this.provincia,
    this.comarca,
    this.municipi,
    this.categories,
    this.free = false,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      code: (json['code']).toString().trim(),
      title: (json['denomination']).toString().trim(),
      subtitle: EventTextUtils.stringOrNull(json['subtitle']),
      description: EventTextUtils.stringOrNull(json['description']),
      url_activity: EventTextUtils.rawStringOrNull(json['url_activity']),
      url_ticket: EventTextUtils.rawStringOrNull(json['url_ticket']),
      schedule: EventTextUtils.stringOrNull(json['schedule']),
      modality: EventTextUtils.stringOrNull(json['modality']),
      urls: EventTextUtils.rawStringOrNull(json['urls']),
      images: EventTextUtils.rawStringOrNull(json['images']),
      videos: EventTextUtils.rawStringOrNull(json['videos']),
      documents: EventTextUtils.rawStringOrNull(json['documents']),
      address: EventTextUtils.stringOrNull(json['address']),
      email: EventTextUtils.rawStringOrNull(json['email']),
      locality: EventTextUtils.stringOrNull(json['locality']),
      url_locality: EventTextUtils.rawStringOrNull(json['url_locality']),
      startDate: EventTextUtils.stringOrNull(json['start_date']),
      endDate: EventTextUtils.stringOrNull(json['end_date']),
      provincia: EventTextUtils.labelOrNull(json['provincia']),
      comarca: EventTextUtils.labelOrNull(json['comarca']),
      municipi: EventTextUtils.labelOrNull(json['municipi']),
      categories: EventTextUtils.categoriesToCapitalizedString(json['categories']),
      free: json['free'] == true,
    );
  }

  String get location {
    final parts = [municipi, provincia]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Per determinar';
    return parts.join(', ');
  }

  static String? _formatDisplayDate(String? input) {
    if (input == null) return null;
    try {
      final date = DateTime.parse(input);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year;
      return '$day/$month/$year';
    } catch (e) {
      return input; // Fallback just in case the API format changes
    }
  }

  String get displayDateRange {
    final start = _formatDisplayDate(startDate);
    final end = _formatDisplayDate(endDate);

    if (start == null && end == null) return 'Per determinar';
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start - Per determinar';
    return 'Per determinar - $end';
  }

  String get displayCategory {
    final raw = categories?.trim();
    if (raw == null || raw.isEmpty) return 'General';
    return raw;
  }

  String get displaySubtitle {
    final raw = subtitle?.trim();
    if (raw == null || raw.isEmpty) return ' ';
    return raw;
  }
}