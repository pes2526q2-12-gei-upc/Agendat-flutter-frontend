class EventPayloadUtils {
  const EventPayloadUtils._();

  static bool hasCoordinates(Map<String, dynamic> json) {
    final latitude = extractLatitude(json);
    final longitude = extractLongitude(json);
    return latitude != null && longitude != null;
  }

  static double? extractLatitude(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      return _toDouble(location['latitude'] ?? location['lat']);
    }

    final coordinates = json['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      // GeoJSON habitualment es [lng, lat].
      return _toDouble(coordinates[1]);
    }

    return _toDouble(json['latitude'] ?? json['lat']);
  }

  static double? extractLongitude(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      return _toDouble(
        location['longitude'] ??
            location['lng'] ??
            location['lon'] ??
            location['long'],
      );
    }

    final coordinates = json['coordinates'];
    if (coordinates is List && coordinates.length >= 2) {
      // GeoJSON habitualment es [lng, lat].
      return _toDouble(coordinates[0]);
    }

    return _toDouble(
      json['longitude'] ?? json['lng'] ?? json['lon'] ?? json['long'],
    );
  }

  static String extractId(Map<String, dynamic> json) {
    return (json['code'] ?? json['id'] ?? '').toString().trim();
  }

  static String extractTitle(Map<String, dynamic> json) {
    return (json['title'] ?? json['denomination'] ?? json['name'] ?? '')
        .toString()
        .trim();
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
