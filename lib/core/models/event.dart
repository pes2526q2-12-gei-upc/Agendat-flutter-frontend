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
      municipi,
      provincia,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isEmpty ? 'Per determinar' : parts.join(', ');
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
    if (categories.isEmpty) return 'General';
    return categories.map(_capitalize).join(', ');
  }

  String get displaySubtitle {
    final raw = subtitle?.trim();
    return (raw == null || raw.isEmpty) ? 'Sense descripció' : raw;
  }

  // ── Private helpers ──────────────────────────────────────────────

  static String? _formatDisplayDate(DateTime? date) {
    if (date == null) return null;
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
