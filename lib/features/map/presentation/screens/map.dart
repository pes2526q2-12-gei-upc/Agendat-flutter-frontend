import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:agendat/core/models/event_map.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/async_epoch.dart';
import 'package:agendat/features/map/data/device_location_service.dart';
import 'package:agendat/features/map/data/map_navigation_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:agendat/core/widgets/app_search_bar.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:agendat/features/map/presentation/models/map_filters.dart';
import 'package:agendat/features/map/presentation/widgets/map_controls.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';
import 'package:agendat/features/map/presentation/widgets/map_filter_button.dart';
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

  /// Filtres locals del mapa: per defecte avui i sense categoria.
  late MapFilters _filters;

  /// Text de cerca aplicat al backend (paràmetre `name` de `/api/events/map/`).
  /// Només s'actualitza quan l'usuari prem Enter / botó de cerca.
  String _submittedName = '';

  /// Marcadors actuals construïts a partir de l'última crida a
  /// `/api/events/map/`.
  List<MapEventMarker> _markers = const <MapEventMarker>[];

  /// Estat de càrrega de la llista de pins.
  bool _isLoadingPins = true;
  Object? _pinsError;

  final AsyncEpoch _pinsEpoch = AsyncEpoch();

  MapEventMarker? _selectedMarker;

  /// Preview retornada per `/api/events/{code}/preview/` quan l'usuari
  /// toca una xinxeta. Mentre està a `null` i [_isLoadingPreview] és
  /// `true` la targeta mostra l'esquelet de càrrega.
  EventPreview? _selectedPreview;
  bool _isLoadingPreview = false;

  final AsyncEpoch _previewEpoch = AsyncEpoch();

  bool _isFiltersOpen = false;

  final double _minZoom = 8.0;
  final double _maxZoom = 18.0;
  final double _radius = 40.0;

  @override
  void initState() {
    super.initState();
    _filters = MapFilters.today();
    _loadCurrentLocation();
    _loadPins(forceRefresh: true);
  }

  Future<void> _loadCurrentLocation() async {
    final location = await _deviceLocationService.getCurrentLocation();
    if (location == null || !mounted) return;
    setState(() => _currentUserLocation = location);
  }

  Future<void> _loadPins({bool forceRefresh = false}) async {
    final epoch = _pinsEpoch.bump();
    setState(() {
      _isLoadingPins = true;
      _pinsError = null;
    });

    try {
      final pins = await _eventsQuery.getEventMapPins(
        date: _filters.date,
        category: _filters.category,
        name: _submittedName.isEmpty ? null : _submittedName,
        forceRefresh: forceRefresh,
      );
      if (!mounted || !_pinsEpoch.isCurrent(epoch)) return;
      final markers = buildMarkersFromPins(pins);
      setState(() {
        _markers = markers;
        _isLoadingPins = false;
        // Si l'event seleccionat ja no apareix als marcadors actuals, el
        // descartem perquè no quedi una targeta orfe.
        if (_selectedMarker != null &&
            !markers.any((m) => m.code == _selectedMarker!.code)) {
          _clearSelection();
        }
      });
    } catch (e) {
      if (!mounted || !_pinsEpoch.isCurrent(epoch)) return;
      setState(() {
        _pinsError = e;
        _isLoadingPins = false;
      });
    }
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

  Future<void> _openNavigationToEvent(MapEventMarker marker) async {
    final origin = _currentUserLocation ?? _center;
    final launched = await _mapNavigationService.openNavigation(
      origin: origin,
      destination: marker.point,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation.')),
      );
    }
  }

  void _openEventDetails(MapEventMarker marker) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventScreen(eventCode: marker.code)),
    );
  }

  void _clearSelection() {
    _selectedMarker = null;
    _selectedPreview = null;
    _isLoadingPreview = false;
  }

  void _closeSelectedEventCard() {
    setState(_clearSelection);
  }

  Future<void> _onMarkerTap(MapEventMarker marker) async {
    final epoch = _previewEpoch.bump();
    setState(() {
      _selectedMarker = marker;
      _selectedPreview = null;
      _isLoadingPreview = true;
    });

    try {
      final preview = await _eventsQuery.getEventPreview(marker.code);
      if (!mounted || !_previewEpoch.isCurrent(epoch)) return;
      setState(() {
        _selectedPreview = preview;
        _isLoadingPreview = false;
      });
    } catch (_) {
      if (!mounted || !_previewEpoch.isCurrent(epoch)) return;
      setState(() => _isLoadingPreview = false);
    }
  }

  /// Actualitza el paràmetre `name` enviat al backend i recarrega els pins.
  /// Només es dispara quan l'usuari prem Enter / botó de cerca.
  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed == _submittedName) return;
    _submittedName = trimmed;
    _loadPins();
  }

  void _onApplyFilters(MapFilters filters) {
    if (filters == _filters) return;
    setState(() {
      _filters = filters;
      _clearSelection();
    });
    _loadPins();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final mapContentWidth = math.min(screenWidth, 900.0);

    final eventMarkers = buildEventMarkers(
      markers: _markers,
      onMarkerTap: _onMarkerTap,
    );

    final selectedMarker = _selectedMarker;
    final hasCurrentLocation = _currentUserLocation != null;
    double distanceKm = 0.0;
    if (selectedMarker != null && _currentUserLocation != null) {
      distanceKm = _distanceCalculator.as(
        LengthUnit.Kilometer,
        _currentUserLocation!,
        selectedMarker.point,
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
                              if (_isLoadingPins && _markers.isEmpty)
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                )
                              else if (_pinsError != null && _markers.isEmpty)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          'No s\'han pogut carregar els esdeveniments.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              else if (_markers.isEmpty)
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
                                child: MapFilterButton(
                                  currentFilters: _filters,
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
                              if (selectedMarker != null)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: MapSelectedEventCard(
                                    marker: selectedMarker,
                                    preview: _selectedPreview,
                                    isLoading: _isLoadingPreview,
                                    hasCurrentLocation: hasCurrentLocation,
                                    distanceKm: distanceKm,
                                    onRoutePressed: () =>
                                        _openNavigationToEvent(selectedMarker),
                                    onMoreDetailsPressed: () =>
                                        _openEventDetails(selectedMarker),
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
