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

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final code = (json['code'] ?? '').toString().trim();
    final title = (json['title'] ?? '').toString().trim();

    if (code.isEmpty || title.isEmpty) {
      throw const FormatException('Each event must include code and title');
    }

    return EventItem(
      code: code,
      title: title,
      subtitle: _stringOrNull(json['subtitle'] ?? json['description']),
      startDate: _stringOrNull(json['startDate'] ?? json['start_date']),
      endDate: _stringOrNull(json['endDate'] ?? json['end_date']),
      provincia: _stringOrNull(json['provincia']),
      comarca: _stringOrNull(json['comarca']),
      municipi: _stringOrNull(json['municipi']),
      categories: _stringOrNull(json['categories'] ?? json['category']),
      free: _toBool(json['free'] ?? json['isFree'] ?? json['is_free']),
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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

  String get location {
    final parts = [municipi, comarca, provincia]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'No especificat';
    return parts.join(', ');
  }

  String get displayDate {
    final raw = startDate?.trim();
    if (raw == null || raw.isEmpty) return 'No especificada';
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
  static const String _eventsPath = '/events';

  int _selectedTabIndex = 3;
  late Future<List<EventItem>> _eventsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _eventsFuture = fetchEvents();
  }

  Future<List<EventItem>> fetchEvents() async {
    final today = DateTime.now();
    final todayDate =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse('${_baseUrl()}$_eventsPath').replace(
      queryParameters: {'date': todayDate},
    );

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

  List<EventItem> _parseEventsBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EventItem.fromJson)
          .toList();
    }
    if (decoded is Map<String, dynamic> && decoded['events'] is List) {
      final events = decoded['events'] as List<dynamic>;
      return events
          .whereType<Map<String, dynamic>>()
          .map(EventItem.fromJson)
          .toList();
    }

    throw const FormatException('Unexpected response format for /events');
  }

  String _baseUrl() {
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (customBaseUrl.isNotEmpty) return customBaseUrl;

    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }

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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
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
            color: const Color(0xff1D1617).withOpacity(0.11),
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
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
    );
  }
}