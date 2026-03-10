import 'package:agendat/core/services/events_api_service.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart' as navBar;
import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/filterButton.dart';
import 'package:agendat/core/widgets/app_search_bar.dart' as bar;

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

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString().trim();
    final title = (json['title'] ?? json['denomination'] ?? '')
        .toString()
        .trim();

    if (code.isEmpty || title.isEmpty) {
      throw const FormatException('Each event must include code and title');
    }

    return EventItem(
      code: code,
      title: title,
      subtitle: _stringOrNull(json['subtitle'] ?? json['description']),
      startDate: _stringOrNull(json['startDate'] ?? json['start_date']),
      endDate: _stringOrNull(json['endDate'] ?? json['end_date']),
      provincia: _labelOrNull(json['provincia']),
      comarca: _labelOrNull(json['comarca']),
      municipi: _labelOrNull(json['municipi']),
      categories: _categoriesToString(json['categories'] ?? json['category']),
      free: _toBool(json['free'] ?? json['isFree'] ?? json['is_free']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : _capitalizeFirst(text);
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  static String _normalizeLabel(String text) {
    return text
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _labelOrNull(dynamic value) {
    if (value == null) return null;
    final normalized = _normalizeLabel(value.toString());
    return normalized.isEmpty ? null : _capitalizeFirst(normalized);
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static String? _categoriesToString(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      return _labelOrNull(value);
    }

    if (value is List) {
      final names = <String>[];
      for (final item in value) {
        if (item == null) continue;
        if (item is Map<String, dynamic>) {
          final name = _labelOrNull(item['name']);
          if (name != null) names.add(name);
          continue;
        }
        final text = _labelOrNull(item);
        if (text != null) names.add(text);
      }
      if (names.isEmpty) return null;
      return names.join(', ');
    }

    return _labelOrNull(value);
  }

  String get location {
    final parts = [
      municipi,
      provincia,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'No especificat';
    return parts.join(', ');
  }

  String get displayDate {
    final raw = startDate?.trim();
    if (raw == null || raw.isEmpty) return 'No especificada';

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString().padLeft(4, '0');
      return '$day-$month-$year';
    }

    final normalized = raw.split('T').first.split(' ').first;
    final parts = normalized.split(RegExp(r'[-/]'));
    if (parts.length == 3) {
      if (parts[0].length == 4) {
        final year = parts[0].padLeft(4, '0');
        final month = parts[1].padLeft(2, '0');
        final day = parts[2].padLeft(2, '0');
        return '$day-$month-$year';
      }

      final day = parts[0].padLeft(2, '0');
      final month = parts[1].padLeft(2, '0');
      final year = parts[2].padLeft(4, '0');
      return '$day-$month-$year';
    }

    return raw;
  }

  String get displayCategory {
    final raw = categories?.trim();
    if (raw == null || raw.isEmpty) return 'General';
    return raw;
  }

  String get displaySubtitle {
    final raw = subtitle?.trim();
    if (raw == null || raw.isEmpty) return 'Sense descripcio';
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
  int _selectedTabIndex = 0;
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
      bottomNavigationBar: navBar.AppNavigationBar(
        currentIndex: _selectedTabIndex,
      ),
      appBar: appBar(),
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
    return Container(
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
    );
  }

  Text eventPlace(EventItem event) {
    return Text(
      'Lloc: ${event.location}',
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    );
  }

  Text eventPayment(EventItem event) {
    return Text(
      event.free ? 'Gratuit' : 'De pagament',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }

  Text eventDate(EventItem event) {
    return Text(
      'Data: ${event.displayDate}',
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

  AppBar appBar() {
    return AppBar(
      title: const Text(
        "Agenda't",
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
    );
  }
}
