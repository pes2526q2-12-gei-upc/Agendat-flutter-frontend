import 'package:flutter/material.dart';

class EventTextUtils {
  const EventTextUtils._();

  // Deep red used for primary actions and header (matches design).
  static const kPrimaryRed = Color(0xFFB71C1C);

  // Catalan month abbreviations for the calendar icon (index 0 = January).
  static const List<String> calendarMonthNames = [
    'GEN',
    'FEB',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SEP',
    'OCT',
    'NOV',
    'DES',
  ];

  // Returns a trimmed string or null if the value is null/empty.
  static String? trimmedOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  // Normalizes text for comparisons that should ignore case and spaces.
  static String normalizedForComparison(String text) {
    return text.trim().toLowerCase();
  }

  static bool equalsIgnoringCase(String left, String right) {
    return normalizedForComparison(left) == normalizedForComparison(right);
  }

  // Converts value to string or returns null if empty
  static String? rawStringOrNull(dynamic value) {
    final text = trimmedOrNull(value);
    if (text == null) return null;
    return text.isEmpty ? null : text;
  }

  // Converts value to string or returns null if empty
  static String? stringOrNull(dynamic value) {
    final text = trimmedOrNull(value);
    if (text == null) return null;
    return text.isEmpty ? null : capitalizeFirst(text);
  }

  static String? formatDisplayDate(DateTime? date) {
    if (date == null) return null;
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
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
    final text = trimmedOrNull(value);
    if (text == null) return null;
    final normalized = normalizeLabel(text);
    return normalized.isEmpty ? null : capitalizeFirst(normalized);
  }

  // Converts a categories list into a readable comma-separated string capitalized
  static String? categoriesToCapitalizedString(List<dynamic>? value) {
    if (value == null || value.isEmpty) return null;

    final names = value
        .map((item) {
          if (item is String) return labelOrNull(item);
          if (item is Map) {
            return labelOrNull(item['name']);
          }
          return null;
        })
        .whereType<String>()
        .toList();

    if (names.isEmpty) return null;
    return names.map(capitalizeFirst).join(', ');
  }
}
