import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// PENDENT:
// - Passar de dades fake a dades reals del backend.
// - Afegir imatge/preu/categoria a cada esdeveniment

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

/// Genera esdeveniments de prova per visualitzar al mapa.
List<MapEventMarkerData> buildDemoEvents(LatLng center) {
  return <MapEventMarkerData>[
    MapEventMarkerData(id: 'e1', title: 'Concert al Centre', point: center),
    MapEventMarkerData(
      id: 'e2',
      title: 'Food Market',
      point: LatLng(center.latitude + 0.012, center.longitude + 0.010),
    ),
    MapEventMarkerData(
      id: 'e3',
      title: 'Exposicio Urbana',
      point: LatLng(center.latitude - 0.010, center.longitude - 0.014),
    ),
    MapEventMarkerData(
      id: 'e4',
      title: 'Meetup Tech',
      point: LatLng(center.latitude + 0.006, center.longitude - 0.018),
    ),
  ];
}

// Crea els pins vermells
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
