/*import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/appBar.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart' as navBar;
import 'package:agendat/core/utils/event_text_utils.dart';


class EventItem {
  final String code;
  final String title;
  final String? subtitle;
  final String? description;
  final String? url_activity;
  final String? url_ticket;
  final String? schedule;
  final bool free;
  final String? modality;
  final String? urls;
  final String? images;
  final String? videos;
  final String? documents;
  final String? address;
  final String? email;
  final String? locality;
  final String? url_locality;
  final String? startDate;
  final String? endDate;
  final String? provincia;
  final String? comarca;
  final String? municipi;
  final String? categories;

  const EventItem({
    required this.code,
    required this.title,
    this.description,
    this.subtitle,
    this.url_activity,
    this.url_ticket,
    this.schedule,
    this.modality,
    this.urls,
    this.images,
    this.videos,
    this.documents,
    this.address,
    this.email,
    this.locality,
    this.url_locality,
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
      description: EventTextUtils.stringOrNull(json['description']),
      url_activity: EventTextUtils.rawStringOrNull(json['url_activity']),
      url_ticket: EventTextUtils.rawStringOrNull(json['url_ticket']),
      schedule: EventTextUtils.stringOrNull(json['schedule']),
      modality: EventTextUtils.stringOrNull(json['modality']),
      urls: EventTextUtils.rawStringOrNull(json['urls']),
      images: EventTextUtils.rawStringOrNull(json['images']),
      videos: EventTextUtils.rawStringOrNull(json['videos']),
      documents: EventTextUtils.rawStringOrNull(json['documents']),
      address: EventTextUtils.stringOrNull(json['address']),
      email: EventTextUtils.rawStringOrNull(json['email']),
      locality: EventTextUtils.stringOrNull(json['locality']),
      url_locality: EventTextUtils.rawStringOrNull(json['url_locality']),
      startDate: EventTextUtils.stringOrNull(json['start_date']),
      endDate: EventTextUtils.stringOrNull(json['end_date']),
      provincia: EventTextUtils.labelOrNull(json['provincia']),
      comarca: EventTextUtils.labelOrNull(json['comarca']),
      municipi: EventTextUtils.labelOrNull(json['municipi']),
      categories: EventTextUtils.categoriesToCapitalizedString(json['categories']),
      free: json['free'] == true,
    );
  }

}

class EventScreen extends StatefulWidget {
  const EventScreen({
    super.key,
    required this.eventCode,
  });

  final String eventCode;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  int _selectedTabIndex = 0;

  String get _eventCode => widget.eventCode;

  void _onNavigationTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

late Future<EventItem> _eventFuture;
//final EventApiService _eventApiService = EventApiService();

@override
void initState() {
  super.initState();
  _eventFuture = _loadEvent();
}

Future<EventItem> _loadEvent() async {
  final rawEvent = await _eventApiService.fetchEvent(widget.eventCode);
  return EventItem.fromJson(rawEvent);
}

void _retryLoad() {
  setState(() {
    _eventFuture = _loadEvent();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgendatAppBar(),
      body: FutureBuilder<EventItem>(
  future: _eventFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _retryLoad,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    final event = snapshot.data!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Codi: ${event.code}'),
          Text('Títol: ${event.title}'),
          Text('Subtítol: ${event.subtitle ?? '-'}'),
          Text('Descripció: ${event.description ?? '-'}'),
          Text('URL activitat: ${event.url_activity ?? '-'}'),
          Text('URL tiquet: ${event.url_ticket ?? '-'}'),
          Text('Horari: ${event.schedule ?? '-'}'),
          Text('Gratuït: ${event.free ? 'Sí' : 'No'}'),
          Text('Modalitat: ${event.modality ?? '-'}'),
          Text('URLs: ${event.urls ?? '-'}'),
          Text('Imatges: ${event.images ?? '-'}'),
          Text('Vídeos: ${event.videos ?? '-'}'),
          Text('Documents: ${event.documents ?? '-'}'),
          Text('Adreça: ${event.address ?? '-'}'),
          Text('Email: ${event.email ?? '-'}'),
          Text('Localitat: ${event.locality ?? '-'}'),
          Text('URL localitat: ${event.url_locality ?? '-'}'),
          Text('Data inici: ${event.startDate ?? '-'}'),
          Text('Data fi: ${event.endDate ?? '-'}'),
          Text('Província: ${event.provincia ?? '-'}'),
          Text('Comarca: ${event.comarca ?? '-'}'),
          Text('Municipi: ${event.municipi ?? '-'}'),
          Text('Categoria: ${event.categories ?? '-'}'),
        ],
      ),
    );
  },
),
    );
  }
}
*/