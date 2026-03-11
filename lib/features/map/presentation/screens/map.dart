import 'package:flutter/material.dart';
import 'package:agendat/core/services/device_location_service.dart';
import 'package:agendat/core/services/event_payload_utils.dart';
import 'package:agendat/core/services/events_api_service.dart';
import 'package:agendat/core/services/filters_api_service.dart';
import 'package:agendat/core/services/map_navigation_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart' as navBar;
import 'package:agendat/features/map/presentation/widgets/map_widgets.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller del mapa (per zoom i moviments manuals)
  final MapController _mapController = MapController();
  // Calcula distancia entre dos punts del mapa
  final Distance _distanceCalculator = const Distance();
  final EventsApiService _eventsApiService = EventsApiService();
  final FiltersApiService _filtersApiService = FiltersApiService();
  final DeviceLocationService _deviceLocationService = DeviceLocationService();
  final MapNavigationService _mapNavigationService = MapNavigationService();

  int _selectedTabIndex = 1;

  // Punt inicial (Barcelona) si no tenim ubi de l'usuari
  final LatLng _center = const LatLng(41.3851, 2.1734);
  LatLng? _currentUserLocation;

  List<MapEventMarkerData> _events = <MapEventMarkerData>[];
  MapEventMarkerData? _selectedEvent;
  String _searchQuery = '';
  bool _isLoadingEvents = false;
  String? _eventsLoadError;
  bool _isFiltersOpen = false;
  Map<String, List<String>> _selectedFilters = <String, List<String>>{};

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 40.0;

  @override
  void initState() {
    super.initState();
    _loadEventsFromApi();
    // Intentem obtenir GPS per mostrar ubi i km reals
    _loadCurrentLocation();
  }

  Future<void> _loadEventsFromApi() async {
    setState(() {
      _isLoadingEvents = true;
      _eventsLoadError = null;
    });

    try {
      final rawEvents = _selectedFilters.isEmpty
          ? await _eventsApiService.fetchEvents()
          : await _filtersApiService.fetchEventsByFilters(
              selectedFilters: _selectedFilters,
            );
      final eventsWithCoordinates = rawEvents
          .where(EventPayloadUtils.hasCoordinates)
          .toList();
      if (!mounted) return;

      setState(() {
        _events = buildEventsFromApi(eventsWithCoordinates);
        _selectedEvent = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _eventsLoadError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingEvents = false;
      });
    }
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _deviceLocationService.getCurrentLocation();
    if (location == null) return;
    if (!mounted) return;

    setState(() {
      _currentUserLocation = location;
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
    final origin = _currentUserLocation ?? _center;
    final launched = await _mapNavigationService.openNavigation(
      origin: origin,
      destination: event.point,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No s\'ha pogut obrir la navegació.')),
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

      // Si l'esdeveniment seleccionat ja no surt al filtre, tanquem la targeta
      final selected = _selectedEvent;
      if (selected != null && !_eventMatchesSearch(selected, _searchQuery)) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> _onApplyFilters(Map<String, List<String>> selected) async {
    setState(() {
      _selectedFilters = selected;
      _selectedEvent = null;
    });

    await _loadEventsFromApi();
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
          width: 24,
          height: 24,
          // Punt blau petit per ubi actual
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.18),
            ),
            padding: const EdgeInsets.all(3),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 1.2),
                ),
              ),
            ),
          ),
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "La cultura a prop teu",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: navBar.AppNavigationBar(
        currentIndex: _selectedTabIndex,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Buscador
            bar.AppSearchBar(
              onChanged: _onSearchChanged,
              margin: EdgeInsets.fromLTRB(
                horizontalPadding,
                6,
                horizontalPadding,
                5,
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_isLoadingEvents) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_eventsLoadError != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Error carregant esdeveniments: $_eventsLoadError',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadEventsFromApi,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final maxMapWidth = constraints.maxWidth > 900
                      ? 900.0
                      : constraints.maxWidth;
                  final mapInteractionFlags = _isFiltersOpen
                      ? InteractiveFlag.none
                      : (InteractiveFlag.drag |
                            InteractiveFlag.pinchZoom |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.flingAnimation);

                  return Center(
                    child: SizedBox(
                      width: maxMapWidth,
                      child: Container(
                        margin: EdgeInsets.fromLTRB(6, 6, 6, 6),
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
                                  initialZoom: 12.0,
                                  minZoom: _minZoom,
                                  maxZoom: _maxZoom,
                                  // Per moure el mapa i fer zoom amb els dits
                                  interactionOptions: InteractionOptions(
                                    flags: mapInteractionFlags,
                                  ),
                                ),
                                children: [
                                  // Capa base d'OpenStreetMap
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.agendat',
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
                                  radius: _radius,
                                ),
                              ),
                              // Filtre
                              Positioned(
                                top: 12,
                                right: 12,
                                child: FilterButton(
                                  label: 'Filtres',
                                  radius: _radius,
                                  buttonHeight: 48,
                                  initialSelectedFilters: _selectedFilters,
                                  onApplyFilters: _onApplyFilters,
                                  onSheetVisibilityChanged: (isVisible) {
                                    if (!mounted) return;
                                    setState(() {
                                      _isFiltersOpen = isVisible;
                                    });
                                  },
                                ),
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
