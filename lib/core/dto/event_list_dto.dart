import 'package:agendat/core/dto/category_dto.dart';

/// DTO for the paginated `/api/events/` response.
///
/// Mirrors the DRF pagination envelope: `count` is the total amount of
/// events matching the filters, `next`/`previous` are URLs (null when
/// there isn't a next/previous page) and `results` holds the current page.
class PaginatedEventsDto {
  final int count;
  final String? next;
  final String? previous;
  final List<EventListDto> results;

  const PaginatedEventsDto({
    required this.count,
    this.next,
    this.previous,
    this.results = const [],
  });

  bool get hasNext => next != null && next!.isNotEmpty;

  factory PaginatedEventsDto.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] ?? json['events'];
    final results = rawResults is List
        ? rawResults
              .whereType<Map<String, dynamic>>()
              .map(EventListDto.fromJson)
              .toList()
        : <EventListDto>[];

    final rawCount = json['count'];
    final count = rawCount is num ? rawCount.toInt() : results.length;

    return PaginatedEventsDto(
      count: count,
      next: _stringOrNull(json['next']),
      previous: _stringOrNull(json['previous']),
      results: results,
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}

class EventListDto {
  final String code;
  final String? denomination;
  final String? subtitle;
  final String? description;
  final bool? free;
  final List<CategoryDto> categories;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final String? startDate;
  final String? endDate;
  final double? latitude;
  final double? longitude;

  const EventListDto({
    required this.code,
    this.denomination,
    this.subtitle,
    this.description,
    this.free,
    this.categories = const [],
    this.provincia,
    this.comarca,
    this.municipi,
    this.startDate,
    this.endDate,
    this.latitude,
    this.longitude,
  });

  factory EventListDto.fromJson(Map<String, dynamic> json) {
    return EventListDto(
      code: (json['code'] ?? '').toString().trim(),
      denomination: _trimOrNull(json['denomination'] ?? json['title']),
      subtitle: _trimOrNull(json['subtitle']),
      description: _trimOrNull(json['description']),
      free: _parseBool(json['free']),
      categories: _parseCategories(json['categories']),
      provincia: _trimOrNull(json['provincia']),
      comarca: _trimOrNull(json['comarca']),
      municipi: _trimOrNull(json['municipi']),
      startDate: _trimOrNull(json['start_date']),
      endDate: _trimOrNull(json['end_date']),
      latitude: _parseDouble(json, 'latitude'),
      longitude: _parseDouble(json, 'longitude'),
    );
  }

  static String? _trimOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<CategoryDto> _parseCategories(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CategoryDto.fromJson)
        .toList();
  }

  static double? _parseDouble(Map<String, dynamic> json, String key) {
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      return _toDouble(location[key]);
    }
    return _toDouble(json[key]);
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return null;
  }
}

class EventDto {
  final String code;
  final String? denomination;
  final String? subtitle;
  final bool? free;
  final List<CategoryDto> categories;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final String? startDate;
  final String? endDate;
  final double? latitude;
  final double? longitude;
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

  const EventDto({
    required this.code,
    this.denomination,
    this.subtitle,
    this.free,
    this.categories = const [],
    this.provincia,
    this.comarca,
    this.municipi,
    this.startDate,
    this.endDate,
    this.latitude,
    this.longitude,
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

  factory EventDto.fromJson(Map<String, dynamic> json) {
    return EventDto(
      code: (json['code'] ?? '').toString().trim(),
      denomination: EventListDto._trimOrNull(
        json['denomination'] ?? json['title'],
      ),
      subtitle: EventListDto._trimOrNull(json['subtitle']),
      free: EventListDto._parseBool(json['free']),
      categories: EventListDto._parseCategories(json['categories']),
      provincia: EventListDto._trimOrNull(json['provincia']),
      comarca: EventListDto._trimOrNull(json['comarca']),
      municipi: EventListDto._trimOrNull(json['municipi']),
      startDate: EventListDto._trimOrNull(json['start_date']),
      endDate: EventListDto._trimOrNull(json['end_date']),
      latitude: EventListDto._parseDouble(json, 'latitude'),
      longitude: EventListDto._parseDouble(json, 'longitude'),
      description: EventListDto._trimOrNull(json['description']),
      url_activity: EventListDto._trimOrNull(json['url_activity']),
      url_ticket: EventListDto._trimOrNull(json['url_ticket']),
      schedule: EventListDto._trimOrNull(json['schedule']),
      modality: EventListDto._trimOrNull(json['modality']),
      urls: EventListDto._trimOrNull(json['urls']),
      images: EventListDto._trimOrNull(json['images']),
      videos: EventListDto._trimOrNull(json['videos']),
      documents: EventListDto._trimOrNull(json['documents']),
      address: EventListDto._trimOrNull(json['address']),
      email: EventListDto._trimOrNull(json['email']),
      locality: EventListDto._trimOrNull(json['locality']),
      url_locality: EventListDto._trimOrNull(json['url_locality']),
      telephone_locality: EventListDto._trimOrNull(json['telephone_locality']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'denomination': denomination,
      'subtitle': subtitle,
      'free': free,
      'categories': categories
          .map((c) => {'id': c.id, 'name': c.name})
          .toList(),
      'provincia': provincia,
      'comarca': comarca,
      'municipi': municipi,
      'start_date': startDate,
      'end_date': endDate,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'url_activity': url_activity,
      'url_ticket': url_ticket,
      'schedule': schedule,
      'modality': modality,
      'urls': urls,
      'images': images,
      'videos': videos,
      'documents': documents,
      'address': address,
      'email': email,
      'locality': locality,
      'url_locality': url_locality,
      'telephone_locality': telephone_locality,
    };
  }
}
