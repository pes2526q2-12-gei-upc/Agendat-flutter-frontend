import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Genera alguns markers de prova per visualitzar esdeveniments.
List<Marker> buildEventMarkers(LatLng center) {
  final puntsProva = <LatLng>[
    center,
    LatLng(center.latitude + 0.012, center.longitude + 0.010),
    LatLng(center.latitude - 0.010, center.longitude - 0.014),
    LatLng(center.latitude + 0.006, center.longitude - 0.018),
  ];

  return puntsProva.map((punt) {
    return Marker(
      point: punt,
      width: 80,
      height: 80,
      child: const Icon(
        Icons.location_on,
        color: Color.fromARGB(255, 149, 31, 22),
        size: 40,
      ),
    );
  }).toList();
}
