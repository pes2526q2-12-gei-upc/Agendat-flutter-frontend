import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/features/map/data/device_location_service.dart';
import 'package:agendat/features/map/data/map_navigation_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:agendat/features/map/presentation/widgets/map_controls.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';
import 'package:agendat/features/map/presentation/widgets/map_selected_event_card.dart';

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

  /// Marcadors derivats de la llista d'events que publica la home via
  /// [EventsQuery.publishedEvents].
  List<MapEventMarkerData> _events = <MapEventMarkerData>[];

  MapEventMarkerData? _selectedEvent;

  /// Detall traduït retornat per `/api/events/{code}/` quan l'usuari toca
  /// una xinxeta. Mentre està a `null` i [_isLoadingDetail] és `true` la
  /// targeta mostra l'esquelet de càrrega.
  EventExtended? _selectedDetail;
  bool _isLoadingDetail = false;

  /// Epoch incrementat cada vegada que es selecciona una nova xinxeta. Ens
  /// permet ignorar respostes lentes que han quedat obsoletes (l'usuari ha
  /// canviat de marcador abans que arribés la resposta).
  int _detailEpoch = 0;

  /// Text de cerca aplicat al filtre local dels marcadors. Només
  /// s'actualitza quan l'usuari prem Enter / botó de cerca.
  String _searchQuery = '';

  bool _isFiltersOpen = false;
  EventFilters _activeFilters = const EventFilters();

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 40.0;

  @override
  void initState() {
    super.initState();
    _activeFilters = _eventsQuery.persistedFilters ?? const EventFilters();
    // Inicialitzem amb el que la home ja hagi publicat (pot ser buit si
    // l'usuari ha obert el mapa abans de visitar la home).
    _events = buildMarkersFromEvents(_eventsQuery.publishedEvents.value);
    _eventsQuery.publishedEvents.addListener(_onPublishedEventsChanged);
    _eventsQuery.persistedFiltersListenable.addListener(
      _onSharedFiltersChanged,
    );
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _eventsQuery.publishedEvents.removeListener(_onPublishedEventsChanged);
    _eventsQuery.persistedFiltersListenable.removeListener(
      _onSharedFiltersChanged,
    );
    super.dispose();
  }

  void _onPublishedEventsChanged() {
    if (!mounted) return;
    final markers = buildMarkersFromEvents(_eventsQuery.publishedEvents.value);
    setState(() {
      _events = markers;
      // Si l'event seleccionat ja no apareix als marcadors actuals, el
      // descartem perquè no quedi una targeta orfe.
      if (_selectedEvent != null &&
          !markers.any((m) => m.id == _selectedEvent!.id)) {
        _clearSelection();
      }
    });
  }

  void _onSharedFiltersChanged() {
    if (!mounted) return;
    final sharedFilters = _eventsQuery.persistedFilters ?? const EventFilters();
    if (_activeFilters.toQueryParams().toString() ==
        sharedFilters.toQueryParams().toString()) {
      return;
    }
    setState(() {
      _activeFilters = sharedFilters;
      _clearSelection();
    });
    // No recarreguem res aquí: la home reaccionarà al canvi de filtre,
    // farà la seva crida i tornarà a publicar events; nosaltres els
    // captem amb `_onPublishedEventsChanged`.
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

  void _clearSelection() {
    _selectedEvent = null;
    _selectedDetail = null;
    _isLoadingDetail = false;
  }

  void _closeSelectedEventCard() {
    setState(_clearSelection);
  }

  Future<void> _onMarkerTap(MapEventMarkerData event) async {
    final epoch = ++_detailEpoch;
    setState(() {
      _selectedEvent = event;
      _selectedDetail = null;
      _isLoadingDetail = true;
    });

    try {
      final detail = await _eventsQuery.getEventByCode(event.id);
      if (!mounted || epoch != _detailEpoch) return;
      setState(() {
        _selectedDetail = detail;
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (!mounted || epoch != _detailEpoch) return;
      setState(() => _isLoadingDetail = false);
    }
  }

  bool _eventMatchesSearch(MapEventMarkerData event, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return event.title.toLowerCase().contains(q);
  }

  /// Actualitza el filtre local dels marcadors només quan l'usuari prem
  /// Enter / botó de cerca. El mapa mai fa crides a `/api/events/` per
  /// cerca: tot el filtratge és sobre els marcadors ja carregats per la
  /// home.
  void _onSearchSubmitted(String value) {
    setState(() {
      _searchQuery = value;
      final selected = _selectedEvent;
      if (selected != null && !_eventMatchesSearch(selected, _searchQuery)) {
        _clearSelection();
      }
    });
  }

  void _onApplyFilters(EventFilters filters) {
    // Publica el filtre compartit; la home recarregarà i el notifier ens
    // farà arribar els nous events automàticament.
    _eventsQuery.setPersistedFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final mapContentWidth = math.min(screenWidth, 900.0);
    final filteredEvents = _events
        .where((event) => _eventMatchesSearch(event, _searchQuery))
        .toList();

    final eventMarkers = buildEventMarkers(
      events: filteredEvents,
      onMarkerTap: _onMarkerTap,
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
      backgroundColor: AppThemeTokens.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: mapContentWidth,
                child: AppSearchBar(
                  onSubmitted: _onSearchSubmitted,
                  textInputAction: TextInputAction.search,
                  margin: const EdgeInsets.fromLTRB(
                    AppScreenSpacing.horizontal,
                    AppScreenSpacing.section,
                    AppScreenSpacing.horizontal,
                    AppScreenSpacing.section,
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxMapWidth = math.min(
                    constraints.maxWidth,
                    mapContentWidth,
                  );

                  return Center(
                    child: SizedBox(
                      width: maxMapWidth,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(
                          AppScreenSpacing.horizontal,
                          0,
                          AppScreenSpacing.horizontal,
                          AppScreenSpacing.section,
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
                              if (_events.isEmpty)
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          'No hi ha esdeveniments per mostrar.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
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
                                    detail: _selectedDetail,
                                    isLoading: _isLoadingDetail,
                                    hasCurrentLocation: hasCurrentLocation,
                                    distanceKm: distanceKm,
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
