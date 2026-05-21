import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agendat/core/api/api_error_utils.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/utils/async_epoch.dart';
import 'package:agendat/core/widgets/filter_button.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;
import 'package:agendat/core/widgets/main_app_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/l10n/app_localizations.dart';

class VisualizeScreen extends StatefulWidget {
  const VisualizeScreen({super.key});

  @override
  State<VisualizeScreen> createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  /// Píxels per damunt del final de la llista a partir dels quals dispararem
  /// la càrrega de la pàgina següent (com fa Instagram).
  static const double _loadMoreThresholdPx = 300;

  /// Mida fixa de pàgina per a cada crida a `/api/events/`.
  static const int _pageSize = EventsApi.defaultPageSize;

  final EventsQuery _eventsQuery = EventsQuery.instance;
  final ScrollController _scrollController = ScrollController();

  late final EventFilters _defaultFilters;
  EventFilters _activeFilters = const EventFilters();

  final List<Event> _events = <Event>[];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  Object? _error;

  final AsyncEpoch _requestEpoch = AsyncEpoch();

  /// Text de cerca aplicat al backend (paràmetre `name`). Només
  /// s'actualitza quan l'usuari prem Enter / botó de cerca.
  ///
  /// No filtrem localment per aquesta cadena: el backend ja fa la cerca
  /// cross-language (tradueix el text a català abans de buscar), i un
  /// filtre local sobre `event.title` el contradiria (típicament cap títol
  /// retornat conté literalment el text en l'idioma de l'usuari).
  String _submittedNameQuery = '';

  DateTime get _todayAtMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void initState() {
    super.initState();
    // Filtre base de la pantalla: a partir d'avui.
    _defaultFilters = EventFilters(dateFrom: _todayAtMidnight);
    _activeFilters = _eventsQuery.persistedFilters ?? _defaultFilters;
    if (_eventsQuery.persistedFilters == null) {
      _eventsQuery.setPersistedFilters(_activeFilters);
    }
    _eventsQuery.persistedFiltersListenable.addListener(
      _onSharedFiltersChanged,
    );
    _scrollController.addListener(_onScroll);
    _loadFirstPage(forceRefresh: true);
  }

  @override
  void dispose() {
    _eventsQuery.persistedFiltersListenable.removeListener(
      _onSharedFiltersChanged,
    );
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSharedFiltersChanged() {
    if (!mounted) return;
    final sharedFilters = _eventsQuery.persistedFilters ?? _defaultFilters;
    final hasChanged = !mapEquals(
      _activeFilters.toQueryParams(),
      sharedFilters.toQueryParams(),
    );
    if (!hasChanged) return;

    _activeFilters = sharedFilters;
    _loadFirstPage();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Sense distància màxima coneguda encara (per ex. abans del primer
    // layout), evitem disparar la càrrega.
    if (!position.hasContentDimensions) return;
    final distanceToBottom = position.maxScrollExtent - position.pixels;
    if (distanceToBottom <= _loadMoreThresholdPx) {
      _loadNextPage();
    }
  }

  /// Combina els filtres compartits actuals amb el `name` aplicat (només
  /// canvia quan l'usuari prem Enter al cercador). Retorna `null` quan no
  /// cal enviar cap filtre a l'API.
  EventFilters? _buildFiltersForRequest() {
    final trimmed = _submittedNameQuery.trim();
    final combined = _activeFilters.copyWith(
      name: () => trimmed.isEmpty ? null : trimmed,
    );
    return combined.isEmpty ? null : combined;
  }

  Future<void> _loadFirstPage({bool forceRefresh = false}) async {
    final epoch = _requestEpoch.bump();
    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _hasMore = true;
      _error = null;
      _events.clear();
    });

    // Quan és un refresc manual, descartem totes les pàgines cacheades del
    // llistat per assegurar que cada pàgina nova torna a fer xarxa.
    if (forceRefresh) {
      _eventsQuery.invalidateLists();
    }

    try {
      final page = await _eventsQuery.getEventsPage(
        filters: _buildFiltersForRequest(),
        offset: 0,
        limit: _pageSize,
        forceRefresh: forceRefresh,
      );
      if (!mounted || !_requestEpoch.isCurrent(epoch)) return;
      setState(() {
        _events
          ..clear()
          ..addAll(page.events);
        _hasMore = page.hasMore;
        _isInitialLoading = false;
      });
      _eventsQuery.publishEvents(_events);
    } catch (e) {
      if (!mounted || !_requestEpoch.isCurrent(epoch)) return;
      setState(() {
        _error = e;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore || !_hasMore || _isInitialLoading) return;
    final epoch = _requestEpoch.current;
    setState(() => _isLoadingMore = true);

    try {
      final page = await _eventsQuery.getEventsPage(
        filters: _buildFiltersForRequest(),
        offset: _events.length,
        limit: _pageSize,
      );
      if (!mounted || !_requestEpoch.isCurrent(epoch)) return;
      setState(() {
        _events.addAll(page.events);
        _hasMore = page.hasMore;
        _isLoadingMore = false;
      });
      _eventsQuery.publishEvents(_events);
    } catch (e) {
      if (!mounted || !_requestEpoch.isCurrent(epoch)) return;
      setState(() => _isLoadingMore = false);
      AppSnackBar.show(
        context,
        userMessageFromError(
          e,
          fallback: 'No s\'han pogut carregar més esdeveniments.',
        ),
      );
    }
  }

  /// Es crida quan l'usuari prem Enter o el botó de cerca del teclat. Si
  /// el text efectiu canvia, recarrega la primera pàgina enviant el
  /// paràmetre `name` al backend.
  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    if (trimmed == _submittedNameQuery) return;
    _submittedNameQuery = trimmed;
    _loadFirstPage();
  }

  void _refresh() {
    _loadFirstPage(forceRefresh: true);
  }

  void _onApplyFilters(EventFilters filters) {
    // Aquí no recarreguem manualment: ho farà el listener compartit.
    _eventsQuery.setPersistedFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: MainAppBar(title: l10n.appName),
      backgroundColor: AppThemeTokens.screenBackground,
      body: Column(
        children: [
          bar.AppSearchBar(
            onSubmitted: _onSearchSubmitted,
            textInputAction: TextInputAction.search,
            margin: const EdgeInsets.fromLTRB(
              AppScreenSpacing.horizontal,
              AppScreenSpacing.section,
              AppScreenSpacing.horizontal,
              AppScreenSpacing.xs,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppScreenSpacing.horizontal,
              0,
              AppScreenSpacing.horizontal,
              AppScreenSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: FilterButton(
                currentFilters: _activeFilters,
                onApplyFilters: _onApplyFilters,
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userMessageFromError(_error!, fallback: l10n.loadEventsFailed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: _refresh, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }

    if (_events.isEmpty && !_isLoadingMore) {
      return RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            Center(child: Text(l10n.noEvents)),
          ],
        ),
      );
    }

    return eventsList(_events);
  }

  Widget eventsList(List<Event> events) {
    // Afegim un slot extra al final per dibuixar la rodeta mentre arriben més.
    final showLoader = _isLoadingMore;
    final itemCount = events.length + (showLoader ? 1 : 0);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppScreenSpacing.horizontal,
          0,
          AppScreenSpacing.horizontal,
          AppScreenSpacing.bottom,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppScreenSpacing.sm),
        itemBuilder: (context, index) {
          if (showLoader && index == events.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return eventCard(events[index]);
        },
      ),
    );
  }

  Widget eventCard(Event event) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          unawaited(
            FeatureNavigation.openEventDetail(context, eventCode: event.code),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color.fromARGB(255, 190, 0, 47),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title takes remaining space
                  Expanded(child: eventTitle(event)),
                  const SizedBox(width: 10),
                  // Category badge stays readable and anchored to the right.
                  Flexible(child: eventCategory(event)),
                ],
              ),
              if (event.subtitle?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 2),
                eventSubtitle(event),
                const SizedBox(height: 2),
              ] else
                const SizedBox(height: 2),
              Row(
                children: [
                  eventDate(event),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      eventPrivacy(event),
                      const SizedBox(height: 2),
                      eventPayment(event),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              eventPlace(event),
            ],
          ),
        ),
      ),
    );
  }

  Text eventPlace(Event event) {
    return Text(
      event.location,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Text eventPayment(Event event) {
    return Text(
      event.free ? 'Gratuït' : 'De pagament',
      textAlign: TextAlign.end,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Text eventPrivacy(Event event) {
    return Text(
      event.displayPrivacy,
      textAlign: TextAlign.end,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color.fromARGB(255, 109, 109, 109),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Text eventDate(Event event) {
    return Text(
      event.displayDateRange,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Text eventSubtitle(Event event) {
    return Text(
      event.subtitle!.trim(),
      style: const TextStyle(
        fontSize: 16,
        color: Color.fromARGB(255, 109, 109, 109),
      ),
    );
  }

  Widget eventCategory(Event event) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 190, 0, 47),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          event.displayCategory,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Text eventTitle(Event event) {
    return Text(
      event.title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
