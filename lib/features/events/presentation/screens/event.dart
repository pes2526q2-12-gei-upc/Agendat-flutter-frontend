import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/agendat_app_bar.dart';
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

  // Keep the selected event code in this screen so it can be used
  // for the detail endpoint call by code.
  String get _eventCode => widget.eventCode;

  void _onNavigationTap(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AgendatAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detall de l\'esdeveniment',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Codi: $_eventCode',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
      bottomNavigationBar: navBar.AppNavigationBar(
        currentIndex: _selectedTabIndex,
      ),
    );
  }
}