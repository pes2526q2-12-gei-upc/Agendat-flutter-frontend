import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/models/event_map.dart';

/// Marker data used by the map screen. Mirrors the lightweight payload
/// returned by `/api/events/map/`: just a code + coordinates.
class MapEventMarker {
  const MapEventMarker({required this.code, required this.point});

  final String code;
  final LatLng point;
}

/// Converts the domain [EventMapPin] list (already filtered server-side)
/// into the local marker shape used by [buildEventMarkers].
List<MapEventMarker> buildMarkersFromPins(List<EventMapPin> pins) {
  return pins
      .map(
        (pin) => MapEventMarker(
          code: pin.code,
          point: LatLng(pin.latitude, pin.longitude),
        ),
      )
      .toList();
}

List<Marker> buildEventMarkers({
  required List<MapEventMarker> markers,
  required ValueChanged<MapEventMarker> onMarkerTap,
}) {
  return markers.map((marker) {
    return Marker(
      point: marker.point,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => onMarkerTap(marker),
        child: const Icon(
          Icons.location_on,
          color: Color.fromARGB(255, 149, 31, 22),
          size: 40,
        ),
      ),
    );
  }).toList();
}
