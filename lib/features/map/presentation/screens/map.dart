import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/widgets/navigationBar.dart';
import 'package:agendat/features/map/presentation/widgets/map_widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final MapController mapController = MapController();

  // Index de la pestanya activa de la barra inferior.
  int _selectedTabIndex = 1;

  // Barcelona de punt inicial.
  final LatLng _center = const LatLng(41.3851, 2.1734);

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 10.0;

  void _onNavigationTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _zoomIn() {
    final zoomAra = mapController.camera.zoom;
    final zoomNou = (zoomAra + 1).clamp(_minZoom, _maxZoom).toDouble();
    mapController.move(_center, zoomNou);
  }

  void _zoomOut() {
    final zoomAra = mapController.camera.zoom;
    final zoomNou = (zoomAra - 1).clamp(_minZoom, _maxZoom).toDouble();
    mapController.move(_center, zoomNou);
  }

  @override
  Widget build(BuildContext context) {
    final eventMarkers = buildEventMarkers(_center);

    return Scaffold(
      bottomNavigationBar: AgendatBottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onNavigationTap,
      ),
      body: Column(
        children: [
          // Barra de cerca a dalt.
          const MapSearchBar(),

          // Mapa a la part central.
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Stack(
                  children: [
                    // Capa del mapa.
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 13.0,
                        minZoom: _minZoom,
                        maxZoom: _maxZoom,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.agendat',
                          maxNativeZoom: 19,
                          maxZoom: 19,
                        ),
                        MarkerLayer(markers: eventMarkers),
                      ],
                    ),

                    // Z+ i Z- a dalt a l'esquerra del mapa.
                    Positioned(
                      top: 12,
                      left: 12,
                      child: MapZoomControls(
                        onZoomIn: _zoomIn,
                        onZoomOut: _zoomOut,
                      ),
                    ),

                    // Filtre a dalt a la dreta del mapa.
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: MapFilterButton(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
