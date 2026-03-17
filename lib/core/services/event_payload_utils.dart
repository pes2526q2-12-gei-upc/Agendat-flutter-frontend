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
      return _toDouble(location['latitude']);
    }
    return _toDouble(json['latitude']);
  }

  static double? extractLongitude(Map<String, dynamic> json) {
    final location = json['location'];
    if (location is Map<String, dynamic>) {
      return _toDouble(location['longitude']);
    }
    return _toDouble(json['longitude']);
  }

  static String extractId(Map<String, dynamic> json) {
    return (json['code']).toString().trim();
  }

  static String extractTitle(Map<String, dynamic> json) {
    return (json['title'] ?? json['denomination']).toString().trim();
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}
