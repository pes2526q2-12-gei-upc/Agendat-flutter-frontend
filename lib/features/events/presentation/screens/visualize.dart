import 'package:agendat/core/services/events_api_service.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;
import 'package:agendat/core/widgets/appBar.dart';
import 'package:agendat/features/events/presentation/screens/event.dart';

class EventItem {
  final String code;
  final String title;
  final String? subtitle;
  final String? startDate;
  final String? endDate;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final String? categories;
  final bool free;

  const EventItem({
    required this.code,
    required this.title,
    this.subtitle,
    this.startDate,
    this.endDate,
    this.provincia,
    this.comarca,
    this.municipi,
    this.categories,
    this.free = false,
  });

  // factory JSON object to EventItem object
  factory EventItem.fromJson(Map<String, dynamic> json) {
    final code = (json['code']).toString().trim();
    final title = (json['denomination']).toString().trim();

    return EventItem(
      code: code,
      title: title,
      subtitle: EventTextUtils.stringOrNull(json['subtitle']),
      startDate: EventTextUtils.stringOrNull(json['start_date']),
      endDate: EventTextUtils.stringOrNull(json['end_date']),
      provincia: EventTextUtils.labelOrNull(json['provincia']),
      comarca: EventTextUtils.labelOrNull(json['comarca']),
      municipi: EventTextUtils.labelOrNull(json['municipi']),
      categories: EventTextUtils.categoriesToCapitalizedString(
        json['categories'],
      ),
      free: json['free'] ?? false,
    );
  }

  // Returns the event location
  String get location {
    final parts = [
      municipi,
      provincia,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'Per determinar';
    return parts.join(', ');
  }

  // Converts the API date format (DD/MM/YYYY)
  static String? _formatDisplayDate(String? input) {
    if (input == null) return null;

    final date = DateTime.parse(input);

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  // Returns the event date range
  String get displayDateRange {
    final start = _formatDisplayDate(startDate);
    final end = _formatDisplayDate(endDate);

    if (start == null && end == null) return 'Per determinar';
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start - Per determinar';
    return 'Per determinar - $end';
  }

  // Returns the category or a default value
  String get displayCategory {
    final raw = categories?.trim();
    if (raw == null || raw.isEmpty) return 'General';
    return raw;
  }

  // Returns the subtitle or a default text
  String get displaySubtitle {
    final raw = subtitle?.trim();
    if (raw == null || raw.isEmpty) return ' ';
    return raw;
  }
}

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
      color: Colors.white, // Moved the background color here
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14), // Keeps the ripple inside the rounded corners
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              // Passes ONLY the event code to the next screen
              builder: (context) => EventScreen(eventCode: event.code),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Removed color from here so the InkWell ripple is visible
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
