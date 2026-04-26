import 'package:flutter/material.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/features/map/data/device_location_service.dart';
import 'package:agendat/features/map/data/map_navigation_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:agendat/features/map/presentation/widgets/map_controls.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';
import 'package:agendat/features/map/presentation/widgets/map_selected_event_card.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final Distance _distanceCalculator = const Distance();
  final EventsQuery _eventsQuery = EventsQuery.instance;
  final DeviceLocationService _deviceLocationService = DeviceLocationService();
  final MapNavigationService _mapNavigationService = MapNavigationService();

  final LatLng _center = const LatLng(41.3851, 2.1734);
  LatLng? _currentUserLocation;

  List<MapEventMarkerData> _events = <MapEventMarkerData>[];
  MapEventMarkerData? _selectedEvent;
  String _searchQuery = '';
  bool _isLoadingEvents = false;
  String? _eventsLoadError;
  bool _isFiltersOpen = false;
  EventFilters _activeFilters = const EventFilters();

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 40.0;

  @override
  void initState() {
    super.initState();
    _loadEvents();
    _loadCurrentLocation();
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    setState(() {
      _isLoadingEvents = true;
      _eventsLoadError = null;
    });

    try {
      final events = await _eventsQuery.getEvents(
        filters: _activeFilters.isEmpty ? null : _activeFilters,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      setState(() {
        _events = buildMarkersFromEvents(events);
        _selectedEvent = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _eventsLoadError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoadingEvents = false);
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _deviceLocationService.getCurrentLocation();
    if (location == null || !mounted) return;
    setState(() => _currentUserLocation = location);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom + 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    final newZoom = (currentZoom - 1).clamp(_minZoom, _maxZoom).toDouble();
    _mapController.move(_mapController.camera.center, newZoom);
  }

  void _centerOnCurrentLocation() {
    final location = _currentUserLocation;
    if (location == null) return;
    final targetZoom = _mapController.camera.zoom
        .clamp(12.0, _maxZoom)
        .toDouble();
    _mapController.move(location, targetZoom);
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EventScreen(eventCode: event.id)));
  }

  void _closeSelectedEventCard() {
    setState(() => _selectedEvent = null);
  }

  bool _eventMatchesSearch(MapEventMarkerData event, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return event.title.toLowerCase().contains(q);
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      final selected = _selectedEvent;
      if (selected != null && !_eventMatchesSearch(selected, _searchQuery)) {
        _selectedEvent = null;
      }
    });
  }

  Future<void> _onApplyFilters(EventFilters filters) async {
    if (!mounted) return;
    setState(() {
      _activeFilters = filters;
      _selectedEvent = null;
    });
    await _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final mapContentWidth = math.min(screenWidth, 900.0);
    // L'alçada de la card ha de ser suficient per encabir títols llargs
    // (amb ellipsis) i els dos botons.
    final selectedCardHeight = (screenHeight * 0.22).clamp(220.0, 320.0);

    final filteredEvents = _events
        .where((event) => _eventMatchesSearch(event, _searchQuery))
        .toList();

    final eventMarkers = buildEventMarkers(
      events: filteredEvents,
      onMarkerTap: (event) => setState(() => _selectedEvent = event),
    );

    final selectedEvent = _selectedEvent;
    final hasCurrentLocation = _currentUserLocation != null;
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
      appBar: const MainAppBar(title: 'La cultura a prop teu'),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: mapContentWidth,
                child: AppSearchBar(
                  onChanged: _onSearchChanged,
                  margin: const EdgeInsets.fromLTRB(6, 6, 6, 5),
                ),
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
                              onPressed: () => _loadEvents(forceRefresh: true),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final maxMapWidth = math.min(
                    constraints.maxWidth,
                    mapContentWidth,
                  );

                  return Center(
                    child: SizedBox(
                      width: maxMapWidth,
                      child: Container(
                        margin: const EdgeInsets.all(6),
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
                              AbsorbPointer(
                                absorbing: _isFiltersOpen,
                                child: FlutterMap(
                                  mapController: _mapController,
                                  options: MapOptions(
                                    initialCenter: _center,
                                    initialZoom: 12.0,
                                    minZoom: _minZoom,
                                    maxZoom: _maxZoom,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags:
                                              InteractiveFlag.drag |
                                              InteractiveFlag.pinchZoom |
                                              InteractiveFlag.doubleTapZoom |
                                              InteractiveFlag.flingAnimation,
                                        ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.agendat',
                                    ),
                                    MarkerLayer(markers: mapMarkers),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: MapControls(
                                  onZoomIn: _zoomIn,
                                  onZoomOut: _zoomOut,
                                  onCenterOnUserLocation:
                                      _currentUserLocation != null
                                      ? _centerOnCurrentLocation
                                      : null,
                                  radius: _radius,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: FilterButton(
                                  currentFilters: _activeFilters,
                                  onApplyFilters: _onApplyFilters,
                                  onSheetVisibilityChanged: (isVisible) {
                                    if (mounted) {
                                      setState(
                                        () => _isFiltersOpen = isVisible,
                                      );
                                    }
                                  },
                                ),
                              ),
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
