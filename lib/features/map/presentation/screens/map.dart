import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agendat/core/widgets/navigationBar.dart';
import 'package:agendat/features/map/presentation/widgets/map_widgets.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // Controller del mapa (per zoom i moviments manuals)
  final MapController _mapController = MapController();
  // Calcula distancia entre dos punts del mapa
  final Distance _distanceCalculator = const Distance();

  int _selectedTabIndex = 1;

  // Punt inicial (Barcelona) si no tenim ubi de l'usuari
  final LatLng _center = const LatLng(41.3851, 2.1734);
  LatLng? _currentUserLocation;

  late final List<MapEventMarkerData> _events;
  MapEventMarkerData? _selectedEvent;
  String _searchQuery = '';

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 10.0;

  @override
  void initState() {
    super.initState();
    // Carreguem events fake per provar el mapa
    _events = buildDemoEvents(_center);
    // Intentem obtenir GPS per mostrar ubi i km reals
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    // 1) Mirem si el servei de localitzacio esta actiu.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // 2) Mirem permisos i els demanem si cal
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    // 3) Si tot esta be, guardem la ubi actual
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _currentUserLocation = LatLng(position.latitude, position.longitude);
    });
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Future<void> _zoomIn() async {
    final zoomAra = _mapController.camera.zoom;
    final zoomNou = (zoomAra + 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, zoomNou);
  }

  Future<void> _zoomOut() async {
    final zoomAra = _mapController.camera.zoom;
    final zoomNou = (zoomAra - 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, zoomNou);
  }

  Future<void> _openNavigationToEvent(MapEventMarkerData event) async {
    // Si tenim GPS, sortim des d'alla. Si no des del centre
    final origin = _currentUserLocation ?? _center;
    final destination = event.point;

    // iOS -> Apple Maps, la resta -> Google Maps
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    final uri = isIOS
        ? Uri.parse(
            'https://maps.apple.com/?'
            'saddr=${origin.latitude},${origin.longitude}'
            '&daddr=${destination.latitude},${destination.longitude}'
            '&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
          );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut obrir la navegacio.')),
      );
    }
  }

  void _openEventDetails(MapEventMarkerData event) {
    // PENDENT: Navegar a la pantalla de detall quan estigui feta
  }

  void _closeSelectedEventCard() {
    setState(() {
      _selectedEvent = null;
    });
  }

  bool _eventMatchesSearch(MapEventMarkerData event, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return event.title.toLowerCase().contains(q);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;

      // Si l'esdeveniment seleccionat ja no surt al filtre, tanquem la targeta.
      final selected = _selectedEvent;
      if (selected != null && !_eventMatchesSearch(selected, _searchQuery)) {
        _selectedEvent = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mides de pantalla per adaptar layout.
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isCompactWidth = screenWidth < 380;
    final horizontalPadding = isCompactWidth
        ? 12.0
        : screenWidth < 720
        ? 20.0
        : 28.0;
    final selectedCardHeight = (screenHeight * 0.33).clamp(220.0, 340.0);

    final filteredEvents = _events
        .where((event) => _eventMatchesSearch(event, _searchQuery))
        .toList();

    final eventMarkers = buildEventMarkers(
      events: filteredEvents,
      onMarkerTap: (event) {
        setState(() {
          _selectedEvent = event;
        });
      },
    );

    final selectedEvent = _selectedEvent;
    final hasCurrentLocation = _currentUserLocation != null;
    // Distancia en km des del GPS real fins a l'esdeveniment seleccionat
    double distanceKm = 0.0;
    if (selectedEvent != null && _currentUserLocation != null) {
      distanceKm = _distanceCalculator.as(
        LengthUnit.Kilometer,
        _currentUserLocation!,
        selectedEvent.point,
      );
    }

    final mapMarkers = <Marker>[
      ...eventMarkers,
      if (_currentUserLocation != null)
        Marker(
          point: _currentUserLocation!,
          width: 34,
          height: 34,
          // Punt blau petit per ubi actual
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.18),
            ),
            padding: const EdgeInsets.all(4),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      bottomNavigationBar: AgendatBottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onNavigationTap,
      ),
      // Evita que es tapi amb notch/barres del mobil
      body: SafeArea(
        child: Column(
          children: [
            // Buscador de dalt.
            MapSearchBar(
              onChanged: _onSearchChanged,
              margin: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                0,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxMapWidth = constraints.maxWidth > 900
                      ? 900.0
                      : constraints.maxWidth;

                  return Center(
                    child: SizedBox(
                      width: maxMapWidth,
                      child: Container(
                        margin: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          10,
                          horizontalPadding,
                          10,
                        ),
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
                              // FlutterMap per mostrar el mapa que ens dona flutter
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  // Vista inicial.
                                  initialCenter: _center,
                                  initialZoom: 13.0,
                                  minZoom: _minZoom,
                                  maxZoom: _maxZoom,
                                  // Per moure el mapa i fer zoom amb els dits
                                  interactionOptions: const InteractionOptions(
                                    flags:
                                        InteractiveFlag.drag |
                                        InteractiveFlag.pinchZoom |
                                        InteractiveFlag.doubleTapZoom |
                                        InteractiveFlag.flingAnimation,
                                  ),
                                ),
                                children: [
                                  // Capa base d'OpenStreetMap.
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.agendat',
                                    maxNativeZoom: 19,
                                    maxZoom: 19,
                                  ),
                                  MarkerLayer(markers: mapMarkers),
                                ],
                              ),
                              // Botons de zoom
                              Positioned(
                                top: 12,
                                left: 12,
                                child: MapZoomControls(
                                  onZoomIn: _zoomIn,
                                  onZoomOut: _zoomOut,
                                ),
                              ),
                              // Filtre (PENDENT: ara encara no fa res)
                              const Positioned(
                                top: 12,
                                right: 12,
                                child: MapFilterButton(),
                              ),
                              // Targeta de l'esdeveniment seleccionat
                              if (selectedEvent != null)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: MapSelectedEventCard(
                                    event: selectedEvent,
                                    hasCurrentLocation: hasCurrentLocation,
                                    distanceKm: distanceKm,
                                    cardHeight: selectedCardHeight,
                                    onRoutePressed: () =>
                                        _openNavigationToEvent(selectedEvent),
                                    onMoreDetailsPressed: () =>
                                        _openEventDetails(selectedEvent),
                                    onClosePressed: _closeSelectedEventCard,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
