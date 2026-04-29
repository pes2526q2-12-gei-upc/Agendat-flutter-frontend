import 'package:flutter/material.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';

class VisualizeScreen extends StatefulWidget {
  const VisualizeScreen({super.key});

  @override
  State<VisualizeScreen> createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  final EventsQuery _eventsQuery = EventsQuery.instance;
  late Future<List<Event>> _eventsFuture;
  String _query = '';
  EventFilters _activeFilters = const EventFilters();

  @override
  void initState() {
    super.initState();
    _eventsFuture = _eventsQuery.getEvents(forceRefresh: true);
  }

  void _refresh() {
    setState(() {
      _eventsFuture = _eventsQuery.getEvents(
        filters: _activeFilters.isEmpty ? null : _activeFilters,
        forceRefresh: true,
      );
    });
  }

  void _onApplyFilters(EventFilters filters) {
    setState(() {
      _activeFilters = filters;
      _eventsFuture = _eventsQuery.getEvents(
        filters: filters.isEmpty ? null : filters,
      );
    });
  }

  List<Event> _applySearch(List<Event> events) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return events;

    return events.where((event) {
      final subtitle = event.subtitle?.toLowerCase() ?? '';
      final description = event.description?.toLowerCase() ?? '';
      return event.code.toLowerCase().contains(q) ||
          event.title.toLowerCase().contains(q) ||
          subtitle.contains(q) ||
          description.contains(q) ||
          event.displayCategory.toLowerCase().contains(q) ||
          event.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: "Agenda't"),
      body: Column(
        children: [
          bar.AppSearchBar(
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppScreenSpacing.horizontal,
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: FilterButton(
                currentFilters: _activeFilters,
                onApplyFilters: _onApplyFilters,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _refresh,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final events = _applySearch(snapshot.data ?? const []);
                if (events.isEmpty) {
                  return const Center(child: Text('No hi ha esdeveniments.'));
                }

                return eventsList(events);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget eventsList(List<Event> events) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppScreenSpacing.horizontal,
          8,
          AppScreenSpacing.horizontal,
          AppScreenSpacing.bottom,
        ),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => eventCard(events[index]),
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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventScreen(eventCode: event.code),
            ),
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
                  // Category now has a max width to prevent overflow
                  eventCategory(event),
                ],
              ),
              const SizedBox(height: 4),
              eventSubtitle(event),
              const SizedBox(height: 10),
              Row(
                children: [
                  eventDate(event),
                  const Spacer(),
                  eventPayment(event),
                ],
              ),
              const SizedBox(height: 4),
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
    );
  }

  Text eventPayment(Event event) {
    return Text(
      event.free ? 'Gratuït' : 'De pagament',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Text eventDate(Event event) {
    return Text(
      event.displayDateRange,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Text eventSubtitle(Event event) {
    return Text(
      event.displaySubtitle,
      style: const TextStyle(
        fontSize: 16,
        color: Color.fromARGB(255, 109, 109, 109),
      ),
    );
  }

  Widget eventCategory(Event event) {
    return Container(
      // Limits width so it doesn't push the title out
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 190, 0, 47),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        event.displayCategory,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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
