import 'package:flutter/material.dart';
import 'package:agendat/features/map/data/device_location_service.dart';
import 'package:agendat/core/services/event_payload_utils.dart';
import 'package:agendat/core/services/events_api_service.dart';
import 'package:agendat/core/services/filters_api_service.dart';
import 'package:agendat/features/map/data/map_navigation_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/features/map/presentation/widgets/map_widgets.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map controller for zoom and manual movements
  final MapController _mapController = MapController();
  // Calculate distance between two points on the map
  final Distance _distanceCalculator = const Distance();
  final EventsApiService _eventsApiService = EventsApiService();
  final FiltersApiService _filtersApiService = FiltersApiService();
  final DeviceLocationService _deviceLocationService = DeviceLocationService();
  final MapNavigationService _mapNavigationService = MapNavigationService();
  
  // Key for FlutterMap widget to avoid unnecessary rebuilds
  final GlobalKey _flutterMapKey = GlobalKey();

  // Initial point (Barcelona) if we don't have user location
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
    // Try to get GPS to show real location and distances
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
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom + 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, newZoom);
  }

  Future<void> _zoomOut() async {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom - 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, newZoom);
  }

  Future<void> _openNavigationToEvent(MapEventMarkerData event) async {
    final origin = _currentUserLocation ?? _center;
    final launched = await _mapNavigationService.openNavigation(
      origin: origin,
      destination: event.point,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation.')),
      );
    }
  }

  void _openEventDetails(MapEventMarkerData event) {
    // TODO: Navigate to detail screen when implemented
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

      // If the selected event no longer matches the filter, close the card
      final selected = _selectedEvent;
      if (selected != null && !_eventMatchesSearch(selected, _searchQuery)) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> _onApplyFilters(Map<String, List<String>> selected) async {
    if (!mounted) return;
    
    setState(() {
      _selectedFilters = selected;
      _selectedEvent = null;
    });

    await _loadEventsFromApi();
  }

  @override
  Widget build(BuildContext context) {
    // Screen dimensions to adapt layout
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
    // Distance in km from real GPS to selected event
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
          // Small blue dot for current location
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
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
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
                              'Error loading events: $_eventsLoadError',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadEventsFromApi,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final maxMapWidth = constraints.maxWidth > 900
                      ? 900.0
                      : constraints.maxWidth;

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
                              // AbsorbPointer to disable interaction when filters are open
                              AbsorbPointer(
                                absorbing: _isFiltersOpen,
                                child: FlutterMap(
                                  key: _flutterMapKey,
                                  mapController: _mapController,
                                  options: MapOptions(
                                    // Initial view
                                    initialCenter: _center,
                                    initialZoom: 12.0,
                                    minZoom: _minZoom,
                                    maxZoom: _maxZoom,
                                    // To move the map and zoom with fingers
                                    interactionOptions: const InteractionOptions(
                                      flags: InteractiveFlag.drag |
                                          InteractiveFlag.pinchZoom |
                                          InteractiveFlag.doubleTapZoom |
                                          InteractiveFlag.flingAnimation,
                                    ),
                                  ),
                                  children: [
                                    // OpenStreetMap base layer
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName: 'com.example.agendat',
                                    ),
                                    MarkerLayer(markers: mapMarkers),
                                  ],
                                ),
                              ),
                              // Zoom buttons
                              Positioned(
                                top: 12,
                                left: 12,
                                child: MapZoomControls(
                                  onZoomIn: _zoomIn,
                                  onZoomOut: _zoomOut,
                                  radius: _radius,
                                ),
                              ),
                              // Filter button
                              Positioned(
                                top: 12,
                                right: 12,
                                child: FilterButton(
                                  onApplyFilters: _onApplyFilters,
                                  onSheetVisibilityChanged: (isVisible) {
                                    if (mounted) {
                                      setState(() {
                                        _isFiltersOpen = isVisible;
                                      });
                                    }
                                  },
                                ),
                              ),
                              // Selected event card
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
