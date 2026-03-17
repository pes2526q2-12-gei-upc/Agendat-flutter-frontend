class EventFilters {
  final String? category;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? provincia;
  final String? comarca;
  final String? municipi;

  const EventFilters({
    this.category,
    this.dateFrom,
    this.dateTo,
    this.provincia,
    this.comarca,
    this.municipi,
  });

  bool get isEmpty =>
      category == null &&
      dateFrom == null &&
      dateTo == null &&
      provincia == null &&
      comarca == null &&
      municipi == null;

  EventFilters copyWith({
    String? Function()? category,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    String? Function()? provincia,
    String? Function()? comarca,
    String? Function()? municipi,
  }) {
    return EventFilters(
      category: category != null ? category() : this.category,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      provincia: provincia != null ? provincia() : this.provincia,
      comarca: comarca != null ? comarca() : this.comarca,
      municipi: municipi != null ? municipi() : this.municipi,
    );
  }

  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    if (category != null) params['category'] = category!;
    if (dateFrom != null) params['date_from'] = _formatDate(dateFrom!);
    if (dateTo != null) params['date_to'] = _formatDate(dateTo!);
    if (provincia != null) params['provincia'] = provincia!;
    if (comarca != null) params['comarca'] = comarca!;
    if (municipi != null) params['municipi'] = municipi!;
    return params;
  }

  static String _formatDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  @override
  String toString() =>
      'EventFilters(category: $category, dateFrom: $dateFrom, dateTo: $dateTo, '
      'provincia: $provincia, comarca: $comarca, municipi: $municipi)';
}
