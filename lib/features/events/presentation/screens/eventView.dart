import 'package:flutter/material.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.eventCode});

  final String eventCode;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventsQuery _eventsQuery = EventsQuery.instance;
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
    _eventFuture = _eventsQuery.getEventByCode(widget.eventCode);
  }

  void _retryLoad() {
    setState(() {
      _eventFuture = _eventsQuery.getEventByCode(
        widget.eventCode,
        forceRefresh: true,
      );
    });
  }

  // Opens external links using the system browser/app.
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
                // Header section with title and optional subtitle.
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

                // Expandable description section.
                if (_hasText(event.description))
                  _buildSectionCard(
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

                _buildSectionCard(
                  title: 'Informació de l\'esdeveniment',
                  content: Column(
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Data',
                        (startDate == endDate)
                            ? startDate
                            : '$startDate - $endDate',
                      ),
                      if (_hasText(event.schedule))
                        _buildInfoRow(
                          Icons.access_time_rounded,
                          'Horari',
                          event.schedule!.trim(),
                        ),

                      _buildInfoRow(
                        Icons.euro_rounded,
                        'Preu',
                        event.free ? 'Gratuït' : 'De pagament',
                      ),

                      if (_hasText(event.modality))
                        _buildInfoRow(
                          Icons.info_outline_rounded,
                          'Modalitat',
                          event.modality!.trim(),
                        ),

                      if (_hasText(event.address))
                        _buildInfoRow(
                          Icons.location_on_rounded,
                          'Adreça',
                          event.address!.trim(),
                        ),

                      if (_hasText(event.location) &&
                          event.location != 'Per determinar')
                        _buildInfoRow(
                          Icons.map_rounded,
                          'Ubicació',
                          event.location,
                        ),
                    ],
                  ),
                ),

                if (_parseUrl(event.url_activity) != null ||
                    _parseUrl(event.url_locality) != null ||
                    _parseUrl(event.url_ticket) != null)
                  _buildSectionCard(
                    title: 'Enllaços d\'interès',
                    content: Column(
                      children: [
                        if (_parseUrl(event.url_activity) != null)
                          _buildLinkTile(
                            'Web de l\'activitat',
                            _parseUrl(event.url_activity)!,
                          ),
                        if (_parseUrl(event.url_locality) != null)
                          _buildLinkTile(
                            'Web de la localitat',
                            _parseUrl(event.url_locality)!,
                          ),
                        if (_parseUrl(event.url_ticket) != null)
                          _buildLinkTile(
                            'Compra d\'entrades',
                            _parseUrl(event.url_ticket)!,
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

  Widget _buildSectionCard({
    required String title,
    required Widget content,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 202, 3, 3),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  // Shared row renderer for icon + label/value metadata lines.
  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color.fromARGB(255, 202, 3, 3)),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Standardized tile for opening external resources.
  // isPrimary highlights more important calls to action (e.g., ticket link).
  Widget _buildLinkTile(String label, Uri uri, {bool isPrimary = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.open_in_new_rounded,
        color: isPrimary
            ? const Color.fromARGB(255, 202, 3, 3)
            : Colors.blueGrey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isPrimary
              ? const Color.fromARGB(255, 202, 3, 3)
              : Colors.black87,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () => _openLink(uri),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
