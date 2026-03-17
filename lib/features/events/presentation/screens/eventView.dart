import 'package:flutter/material.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/models/event.dart';

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
  final EventsApi _eventsApi = EventsApi();
  late Future<EventExtended> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = _loadEvent();
  }

  Future<EventExtended> _loadEvent() async {
    return _eventsApi.fetchEventByCode(widget.eventCode);
  }

  void _retryLoad() {
    setState(() {
      _eventFuture = _loadEvent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'Detalls de l\'événement'),
      body: FutureBuilder<EventExtended>(
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
          // Added SingleChildScrollView so long text doesn't overflow the screen!
          return SingleChildScrollView( 
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Codi: ${event.code}'),
                Text('Subtítol: ${event.subtitle ?? '-'}'),
                Text('Descripció: ${event.description ?? '-'}'),
                Text('URL activitat: ${event.url_activity ?? '-'}'),
                Text('URL tiquet: ${event.url_ticket ?? '-'}'),
                Text('Horari: ${event.schedule ?? '-'}'),
                Text('Gratuït: ${event.free ? 'Sí' : 'No'}'),
                Text('Modalitat: ${event.modality ?? '-'}'),
                Text('Adreça: ${event.address ?? '-'}'),
                Text('Localitat: ${event.locality ?? '-'}'),
                Text('Data inici: ${event.startDate ?? '-'}'),
                Text('Data fi: ${event.endDate ?? '-'}'),
                Text('Categoria: ${event.categories.isEmpty ? '-' : event.categories.join(', ')}'),
                Text('Provincia: ${event.provincia ?? '-'}'),
                Text('Comarca: ${event.comarca ?? '-'}'),
                Text('Municipi: ${event.municipi ?? '-'}'),
              ],
            ),
          );
        },
      ),
    );
  }
}