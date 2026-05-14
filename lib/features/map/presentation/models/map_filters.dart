import 'package:flutter/foundation.dart';

/// Lightweight filter state used exclusively by the map screen.
///
/// The map endpoint (`/api/events/map/`) only honours `date`, `category`
/// and `name`. The search-bar text is handled separately as a transient
/// query, so this model carries just the two persisted filters.
@immutable
class MapFilters {
  /// Active day for `/api/events/map/?date=...`. Always set: when the user
  /// does not pick a date we default to today.
  final DateTime date;

  /// Category name (or `null` for "all").
  final String? category;

  const MapFilters({required this.date, this.category});

  factory MapFilters.today() {
    final now = DateTime.now();
    return MapFilters(date: DateTime(now.year, now.month, now.day));
  }

  MapFilters copyWith({DateTime? date, String? Function()? category}) {
    return MapFilters(
      date: date ?? this.date,
      category: category != null ? category() : this.category,
    );
  }

  bool get isDefault {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sameDay =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return sameDay && category == null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapFilters &&
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
        other.category == category;
  }

  @override
  int get hashCode => Object.hash(date.year, date.month, date.day, category);
}
