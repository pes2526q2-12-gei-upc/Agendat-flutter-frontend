import 'package:agendat/core/dto/category_dto.dart';

class EventListDto {
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

  const EventListDto({
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
  });

  factory EventListDto.fromJson(Map<String, dynamic> json) {
    return EventListDto(
      code: (json['code'] ?? '').toString().trim(),
      denomination: _trimOrNull(json['denomination'] ?? json['title']),
      subtitle: _trimOrNull(json['subtitle']),
      free: json['free'] as bool?,
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
}
