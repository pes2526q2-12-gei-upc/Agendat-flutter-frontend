import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/services/app_language.dart';
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
  /// A partir de quants caràcters val la pena enviar la cerca al backend per
  /// ampliar els marcadors. Per sota d'aquest llindar només es manté el
  /// filtre local instantani.
  static const int _minServerSearchLength = 3;

  /// Debounce de la cerca al servidor (per evitar una crida per tecla).
  static const Duration _searchDebounceDuration = Duration(milliseconds: 400);

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

  /// Text de cerca actualment aplicat al backend (paràmetre `name`). Pot
  /// quedar enrere respecte a `_searchQuery` mentre s'aplica el debounce.
  String _appliedServerSearch = '';

  bool _isLoadingEvents = false;
  String? _eventsLoadError;
  bool _isFiltersOpen = false;
  EventFilters _activeFilters = const EventFilters();

  /// Epoch incrementat cada vegada que disparem una nova càrrega de
  /// marcadors. Ens permet ignorar respostes lentes que han quedat
  /// obsoletes (canvi de filtre, nova cerca, etc.).
  int _loadEpoch = 0;

  Timer? _searchDebounceTimer;

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 40.0;

  @override
  void initState() {
    super.initState();
    // Entrem amb el filtre compartit actual (si n'hi ha).
    _activeFilters = _eventsQuery.persistedFilters ?? const EventFilters();
    _loadEvents();
    _loadCurrentLocation();
    // Si canvia el filtre a una altra vista, ens posem al dia aquí.
    _eventsQuery.persistedFiltersListenable.addListener(
      _onSharedFiltersChanged,
    );
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    // Traiem listener
    _eventsQuery.persistedFiltersListenable.removeListener(
      _onSharedFiltersChanged,
    );
    super.dispose();
  }

  void _onSharedFiltersChanged() {
    if (!mounted) return;
    final sharedFilters = _eventsQuery.persistedFilters ?? const EventFilters();
    final hasChanged = !mapEquals(
      _activeFilters.toQueryParams(),
      sharedFilters.toQueryParams(),
    );
    // Si no hi ha canvi real, no recarreguem.
    if (!hasChanged) return;

    setState(() {
      // Apliquem el filtre compartit i netegem selecció de targeta del mapa.
      _activeFilters = sharedFilters;
      _selectedEvent = null;
    });
    // Recarreguem marcadors amb el filtre nou.
    _loadEvents();
  }

  /// Combina els filtres compartits amb el text de cerca actualment enviat
  /// al backend. Retorna `null` si no cal cap filtre.
  EventFilters? _buildFiltersForRequest() {
    final trimmed = _appliedServerSearch.trim();
    final combined = _activeFilters.copyWith(
      name: () => trimmed.isEmpty ? null : trimmed,
    );
    return combined.isEmpty ? null : combined;
  }

  Future<void> _loadEvents({bool forceRefresh = false}) async {
    final epoch = ++_loadEpoch;
    setState(() {
      _isLoadingEvents = true;
      _eventsLoadError = null;
    });

    try {
      // Forcem CA: el mapa només mostra el títol curt al marcador, i si
      // demanéssim l'idioma actiu la mida de pàgina baixaria a 3 (límit
      // de traducció) i el mapa faria moltíssimes crides per cobrir tots
      // els marcadors. El detall (EventScreen) es carrega a part i pot
      // traduir-se quan calgui.
      final events = await _eventsQuery.getEvents(
        filters: _buildFiltersForRequest(),
        forceRefresh: forceRefresh,
        lang: AppLanguage.defaultCode,
      );

      if (!mounted || epoch != _loadEpoch) return;

      setState(() {
        _events = buildMarkersFromEvents(events);
        _selectedEvent = null;
      });
    } catch (e) {
      if (!mounted || epoch != _loadEpoch) return;
      setState(() => _eventsLoadError = e.toString());
    } finally {
      if (mounted && epoch == _loadEpoch) {
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
    _scheduleServerSearch(value);
  }

  /// Programa (amb debounce) una crida al backend per ampliar els
  /// marcadors quan la cerca és prou llarga. Per sota del llindar
  /// [_minServerSearchLength] només es manté el filtre local instantani i,
  /// si abans ja havíem aplicat una cerca al servidor, la retirem
  /// (tornem a tenir els marcadors complets dels filtres actuals).
  void _scheduleServerSearch(String value) {
    _searchDebounceTimer?.cancel();

    final trimmed = value.trim();
    final shouldQueryServer = trimmed.length >= _minServerSearchLength;
    final targetServerQuery = shouldQueryServer ? trimmed : '';

    if (targetServerQuery == _appliedServerSearch) return;

    _searchDebounceTimer = Timer(_searchDebounceDuration, () {
      if (!mounted) return;
      if (targetServerQuery == _appliedServerSearch) return;
      _appliedServerSearch = targetServerQuery;
      _loadEvents();
    });
  }

  void _onApplyFilters(EventFilters filters) {
    // Publica el filtre compartit; la recàrrega la gestiona el listener.
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
      backgroundColor: AppThemeTokens.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: mapContentWidth,
                child: AppSearchBar(
                  onChanged: _onSearchChanged,
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
