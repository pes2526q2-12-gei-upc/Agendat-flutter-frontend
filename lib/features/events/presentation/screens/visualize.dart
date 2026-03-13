import 'package:agendat/core/services/events_api_service.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;
import 'package:agendat/core/widgets/appBar.dart';
import 'package:agendat/features/events/presentation/screens/event.dart';
import 'package:agendat/features/events/data/event_item.dart';

class VisualizeScreen extends StatefulWidget {
  const VisualizeScreen({super.key});

  @override
  State<VisualizeScreen> createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  final EventsApiService _eventsApiService = EventsApiService();
  late Future<List<EventItem>> _eventsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<List<EventItem>> _loadEvents() async {
    final rawEvents = await _eventsApiService.fetchEvents();
    return rawEvents.map(EventItem.fromJson).toList();
  }

  // Reloads the events list
  void _refresh() {
    setState(() {
      _eventsFuture = _loadEvents();
    });
  }

  List<EventItem> _applySearch(List<EventItem> events) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return events;

    return events.where((event) {
      return event.code.toLowerCase().contains(q) ||
          event.title.toLowerCase().contains(q) ||
          event.displaySubtitle.toLowerCase().contains(q) ||
          event.displayCategory.toLowerCase().contains(q) ||
          event.location.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgendatAppBar(),
      body: Column(
        children: [
          bar.AppSearchBar(
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(alignment: Alignment.topLeft, child: FilterButton()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<EventItem>>(
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

  Widget eventsList(List<EventItem> events) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => eventCard(events[index]),
      ),
    );
  }

  Widget eventCard(EventItem event) {
    return Material(
      color: Colors.white, 
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), 
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventScreen(
                eventCode: event.code
                ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                  Expanded(child: eventTitle(event)),
                  const SizedBox(width: 10),
                  eventCategory(event),
                ],
              ),
              const SizedBox(height: 4),
              eventSubtitle(event),
              const SizedBox(height: 10),
              Row(
                children: [eventDate(event), const Spacer(), eventPayment(event)],
              ),
              const SizedBox(height: 4),
              eventPlace(event),
            ],
          ),
        ),
      ),
    );
  }

  Text eventPlace(EventItem event) {
    return Text(
      '${event.location}',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Text eventPayment(EventItem event) {
    return Text(
      event.free ? 'Gratuït' : 'De pagament',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Text eventDate(EventItem event) {
    return Text(
      event.displayDateRange,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Text eventSubtitle(EventItem event) {
    return Text(
      event.displaySubtitle,
      style: const TextStyle(
        fontSize: 16,
        color: Color.fromARGB(255, 109, 109, 109),
      ),
    );
  }

  Container eventCategory(EventItem event) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 190, 0, 47),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        event.displayCategory,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Text eventTitle(EventItem event) {
    return Text(
      event.title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
