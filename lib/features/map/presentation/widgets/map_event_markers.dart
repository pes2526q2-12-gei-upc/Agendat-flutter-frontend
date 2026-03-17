import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/models/event.dart';

class MapEventMarkerData {
  const MapEventMarkerData({
    required this.id,
    required this.title,
    required this.point,
  });

  final String id;
  final String title;
  final LatLng point;
}

/// Maps domain [Event] list to map marker data, dropping events without coords.
List<MapEventMarkerData> buildMarkersFromEvents(List<Event> events) {
  return events
      .where((e) => e.hasCoordinates)
      .map(
        (e) => MapEventMarkerData(
          id: e.code,
          title: e.title,
          point: LatLng(e.latitude!, e.longitude!),
        ),
      )
      .toList();
}

List<Marker> buildEventMarkers({
  required List<MapEventMarkerData> events,
  required ValueChanged<MapEventMarkerData> onMarkerTap,
}) {
  return events.map((event) {
    return Marker(
      point: event.point,
      width: 80,
      height: 80,
      child: GestureDetector(
        onTap: () => onMarkerTap(event),
        child: const Icon(
          Icons.location_on,
          color: Color.fromARGB(255, 149, 31, 22),
          size: 40,
        ),
      ),
    );
  }).toList();
}
