import 'package:flutter/material.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  Uri? _parseUrl(String? urlString) {
    if (!_hasText(urlString)) return null;
    final normalized = urlString!.trim();
    final hasScheme = normalized.startsWith('http://') || normalized.startsWith('https://');
    final urlWithScheme = hasScheme ? normalized : 'https://$normalized';
    final uri = Uri.tryParse(urlWithScheme);
    return (uri != null && uri.hasScheme && uri.host.isNotEmpty) ? uri : null;
  }

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

  Future<void> _openLink(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No s\'ha pogut obrir l\'enllaç')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: 'Detalls de l\'esdeveniment'),
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
          final startDate = EventTextUtils.formatDisplayDate(event.startDate);
          final endDate = EventTextUtils.formatDisplayDate(event.endDate);
          final urlLocalityUri = _parseUrl(event.url_locality);
          final urlActivityUri = _parseUrl(event.url_activity);
          final urlTicketUri = _parseUrl(event.url_ticket);

          const detailStyle = TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 0, 0, 0),
          );

          // Added SingleChildScrollView so long text doesn't overflow the screen!
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_hasText(event.title))
                  Text(
                    event.title, 
                    style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ),
                const SizedBox(height: 8),
                if (_hasText(event.subtitle))
                  Text(
                    '${event.subtitle!.trim()}', 
                      style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 44, 44, 44),
                      ),
                    ),
                    const SizedBox(height: 8),
                if (_hasText(event.description))
                  Text('${event.description!.trim()}',
                   style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 75, 75, 75),
                    ),
                   ),
                  const SizedBox(height: 6),
                if (urlActivityUri != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('URL ativitat: ', style: detailStyle),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openLink(urlActivityUri),
                          child: Text(
                            event.url_activity!.trim(),
                            style: detailStyle.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (urlLocalityUri != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('URL localitat: ', style: detailStyle),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openLink(urlLocalityUri),
                          child: Text(
                            event.url_locality!.trim(),
                            style: detailStyle.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (urlTicketUri != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('URL entrades: ', style: detailStyle),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openLink(urlTicketUri),
                          child: Text(
                            event.url_ticket!.trim(),
                            style: detailStyle.copyWith(
                              color: const Color.fromARGB(255, 18, 107, 180),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_hasText(event.schedule))
                  Text('Horari: ${event.schedule!.trim()}', style: detailStyle),
                Text('Gratuït: ${event.free ? 'Sí' : 'No'}', style: detailStyle),
                if (_hasText(event.modality))
                  Text('Modalitat: ${event.modality!.trim()}', style: detailStyle),
                if (_hasText(event.address))
                  Text('Adreça: ${event.address!.trim()}', style: detailStyle),
                if (startDate == endDate && _hasText(startDate))
                  Text('Data: $startDate', style: detailStyle),
                if (startDate != endDate) ...[
                  if (_hasText(startDate))
                    Text('Data inici: $startDate', style: detailStyle),
                  if (_hasText(endDate))
                    Text('Data fi: $endDate', style: detailStyle),
                ],
                if (event.categories
                    .map((category) => category.trim())
                    .where((category) => category.isNotEmpty)
                    .isNotEmpty)
                  Text(
                    'Categoria: ${event.categories.map((category) => category.trim()).where((category) => category.isNotEmpty).join(', ')}',
                    style: detailStyle,
                  ),
                if (_hasText(event.location) && event.location != 'Per determinar')
                  Text('Ubicació: ${event.location}', style: detailStyle),
              ],
            ),
          );
        },
      ),
    );
  }
}