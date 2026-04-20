import 'package:flutter/material.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/section_card.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/events/presentation/widgets/info_row.dart';
import 'package:agendat/features/events/presentation/widgets/link_tile.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_section.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.eventCode});

  final String eventCode;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventsApi _eventsApi = EventsApi();
  late Future<EventExtended> _eventFuture;
  bool _isDescriptionExpanded = false;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Uri? _parseUrl(String? urlString) {
    if (!_hasText(urlString)) return null;
    final normalized = urlString!.trim();
    final hasScheme =
        normalized.startsWith('http://') || normalized.startsWith('https://');
    final urlWithScheme = hasScheme ? normalized : 'https://$normalized';
    final uri = Uri.tryParse(urlWithScheme);
    return (uri != null && uri.hasScheme && uri.host.isNotEmpty) ? uri : null;
  }

  @override
  void initState() {
    super.initState();
    _eventFuture = _eventsApi.fetchEventByCode(widget.eventCode);
  }

  void _retryLoad() {
    setState(() {
      _eventFuture = _eventsApi.fetchEventByCode(widget.eventCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const MainAppBar(title: 'Detalls'),
      body: FutureBuilder<EventExtended>(
        future: _eventFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryLoad,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final event = snapshot.data!;
          final String startDate =
              EventTextUtils.formatDisplayDate(event.startDate) ?? '';
          final String endDate =
              EventTextUtils.formatDisplayDate(event.endDate) ?? '';
          final List<String> formattedCategories = event.categories
              .map(EventTextUtils.labelOrNull)
              .whereType<String>()
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Capçalera: títol i subtítol (opcional).
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (_hasText(event.subtitle)) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.subtitle!.trim(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const Divider(height: 32, thickness: 1),

                // Secció de valoracions: col·lapsada per defecte, mostra
                // només la mitjana fins que l'usuari la desplega.
                ReviewsSection(eventCode: widget.eventCode),

                // Descripció de l'esdeveniment, amb opció d'expandir/col·lapsar
                // si el text és massa llarg.
                if (_hasText(event.description))
                  SectionCard(
                    title: 'Descripció',
                    trailing: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          _isDescriptionExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 28,
                          color: const Color.fromARGB(255, 202, 3, 3),
                        ),
                      ),
                    ),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description!.trim(),
                          maxLines: _isDescriptionExpanded ? null : 2,
                          overflow: _isDescriptionExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                SectionCard(
                  title: 'Informació de l\'esdeveniment',
                  content: Column(
                    children: [
                      InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Data',
                        value: (startDate == endDate)
                            ? startDate
                            : '$startDate - $endDate',
                      ),
                      if (_hasText(event.schedule))
                        InfoRow(
                          icon: Icons.access_time_rounded,
                          label: 'Horari',
                          value: event.schedule!.trim(),
                        ),

                      InfoRow(
                        icon: Icons.euro_rounded,
                        label: 'Preu',
                        value: event.free ? 'Gratuït' : 'De pagament',
                      ),

                      if (_hasText(event.modality))
                        InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Modalitat',
                          value: event.modality!.trim(),
                        ),

                      if (_hasText(event.address))
                        InfoRow(
                          icon: Icons.location_on_rounded,
                          label: 'Adreça',
                          value: event.address!.trim(),
                        ),

                      if (_hasText(event.location) &&
                          event.location != 'Per determinar')
                        InfoRow(
                          icon: Icons.map_rounded,
                          label: 'Ubicació',
                          value: event.location,
                        ),
                    ],
                  ),
                ),

                if (_parseUrl(event.url_activity) != null ||
                    _parseUrl(event.url_locality) != null ||
                    _parseUrl(event.url_ticket) != null)
                  SectionCard(
                    title: 'Enllaços d\'interès',
                    content: Column(
                      children: [
                        if (_parseUrl(event.url_activity) != null)
                          LinkTile(
                            label: 'Web de l\'activitat',
                            uri: _parseUrl(event.url_activity)!,
                          ),
                        if (_parseUrl(event.url_locality) != null)
                          LinkTile(
                            label: 'Web de la localitat',
                            uri: _parseUrl(event.url_locality)!,
                          ),
                        if (_parseUrl(event.url_ticket) != null)
                          LinkTile(
                            label: 'Compra d\'entrades',
                            uri: _parseUrl(event.url_ticket)!,
                            isPrimary: true,
                          ),
                      ],
                    ),
                  ),

                if (formattedCategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      children: formattedCategories
                          .map(
                            (c) => Chip(
                              label: Text(
                                c,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color.fromARGB(255, 202, 3, 3),
                                ),
                              ),
                              backgroundColor: const Color.fromARGB(
                                255,
                                255,
                                219,
                                219,
                              ),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
