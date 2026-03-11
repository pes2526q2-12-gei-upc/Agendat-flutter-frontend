import 'dart:convert';

import 'package:agendat/core/widgets/navigationBar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    final title = (json['denomination'])
        .toString()
        .trim();

    return EventItem(
      code: code,
      title: title,
      subtitle: _stringOrNull(json['subtitle']),
      startDate: _stringOrNull(json['start_date']),
      endDate: _stringOrNull(json['end_date']),
      provincia: _labelOrNull(json['provincia']),
      comarca: _labelOrNull(json['comarca']),
      municipi: _labelOrNull(json['municipi']),
      categories: _categoriesToString(json['categories']),
      free: json['free'] ?? false,
    );
  }

  // Converts value to string or returns null if empty
  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : _capitalizeFirst(text);
  }

  // Capitalizes the first letter of a string
  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  // Cleans text by replacing dashes/underscores with spaces
  static String _normalizeLabel(String text) {
    return text.replaceAll(RegExp(r'[-_]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // Converts a label to a clean formatted string or returns null
  static String? _labelOrNull(dynamic value) {
    if (value == null) return null;
    final normalized = _normalizeLabel(value.toString());
    return normalized.isEmpty ? null : _capitalizeFirst(normalized);
  }

  // Converts the categories field into a readable string
  static String? _categoriesToString(List<dynamic>? value) {
    if (value == null || value.isEmpty) return null;

    return value
        .map((e) => e['name'] as String)
        .join(', ');
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
    if (raw == null || raw.isEmpty) return 'Sense descripció';
    return raw;
  }
}

class VisualizeScreen extends StatefulWidget {
  const VisualizeScreen({super.key});

  @override
  State<VisualizeScreen> createState() => _VisualizeScreenState();
}

class _VisualizeScreenState extends State<VisualizeScreen> {
  static const String _eventsPath = '/api/events/';

  int _selectedTabIndex = 0;
  late Future<List<EventItem>> _eventsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchEvents();
  }

  // Calls the API and downloads the list of events
  Future<List<EventItem>> fetchEvents() async {
    final today = DateTime.now();
    final todayDate = _formatDate(today);
    final dateFrom = _formatDate(_subtractMonths(today, 6));
    final uri = Uri.parse(
      '${_baseUrl()}$_eventsPath',
    ).replace(queryParameters: {
      'date': todayDate,
      'date_from': dateFrom,
    });

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw Exception(
        'Failed to load events (HTTP ${response.statusCode}) for $uri. Response: $snippet',
      );
    }

    return _parseEventsBody(response.body);
  }

  // Subtracts a number of months from a given date
  DateTime _subtractMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) - months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDayOfTargetMonth = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : date.day;

    return DateTime(year, month, day);
  }

  // Formats a DateTime object into YYYY-MM-DD
  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  // Converts the API response body into a list of EventItem objects
  List<EventItem> _parseEventsBody(String body) {
  final decoded = jsonDecode(body) as List;

  return decoded
      .map((event) => EventItem.fromJson(event))
      .toList();
}

  // Returns the correct API base URL depending on the platform
  String _baseUrl() {
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (customBaseUrl.isNotEmpty) return customBaseUrl;

    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

  // Reloads the events list
  void _refresh() {
    setState(() {
      _eventsFuture = fetchEvents();
    });
  }

  void _onNavigationTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    // TODO: Connect each tab index to real route navigation.
  }

  // Filters events based on the text typed in the search bar
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
      bottomNavigationBar: AgendatBottomNavigationBar(
        currentIndex: _selectedTabIndex,
        onTap: _onNavigationTap,
      ),
      appBar: appBar(),
      body: Column(
        children: [
          searchBar(),
          filterButton(),
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

  Align filterButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 12),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 190, 0, 47),
            foregroundColor: Colors.white,
          ),
          onPressed: () {},
          child: const Text(
            'Filtres',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Container searchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1D1617).withValues(alpha: 0.11),
            blurRadius: 40,
            spreadRadius: 0.0,
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _query = value;
          });
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(15),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
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
