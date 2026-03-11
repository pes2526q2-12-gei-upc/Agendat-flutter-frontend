class EventTextUtils {
  const EventTextUtils._();

  // Converts value to string or returns null if empty
  static String? stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : capitalizeFirst(text);
  }

  // Capitalizes the first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  // Cleans text by replacing dashes/underscores with spaces
  static String normalizeLabel(String text) {
    return text
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Converts a label to a clean formatted string or returns null
  static String? labelOrNull(dynamic value) {
    if (value == null) return null;
    final normalized = normalizeLabel(value.toString());
    return normalized.isEmpty ? null : capitalizeFirst(normalized);
  }

  // Converts a categories list into a readable comma-separated string
  static String? categoriesToString(List<dynamic>? value) {
    if (value == null || value.isEmpty) return null;

    final categories = value
        .map((item) {
          final raw = item is Map<String, dynamic> ? item['name'] : item;
          return stringOrNull(raw);
        })
        .whereType<String>()
        .toList();

    if (categories.isEmpty) return null;
    return categories.join(', ');
  }
}
