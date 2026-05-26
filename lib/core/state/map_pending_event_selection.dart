import 'package:flutter/foundation.dart';

/// Event that should be highlighted when the map tab opens.
class MapPendingEventSelection {
  const MapPendingEventSelection({
    required this.eventCode,
    required this.latitude,
    required this.longitude,
    this.filterDate,
  });

  final String eventCode;
  final double latitude;
  final double longitude;

  /// When set, the map reloads pins for this day so the event is visible.
  final DateTime? filterDate;
}

final ValueNotifier<MapPendingEventSelection?>
mapPendingEventSelectionNotifier = ValueNotifier<MapPendingEventSelection?>(
  null,
);

void setMapPendingEventSelection(MapPendingEventSelection selection) {
  mapPendingEventSelectionNotifier.value = selection;
}

MapPendingEventSelection? consumeMapPendingEventSelection() {
  final pending = mapPendingEventSelectionNotifier.value;
  mapPendingEventSelectionNotifier.value = null;
  return pending;
}
