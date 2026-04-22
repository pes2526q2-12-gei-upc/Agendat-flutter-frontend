import 'package:flutter/material.dart';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/api/events_api.dart';
import 'package:agendat/core/api/sessions_api.dart';
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
  final EventsApi _eventsApi = EventsApi();
  final SessionsApi _sessionsApi = SessionsApi();
  late Future<EventExtended> _eventFuture;
  bool _isDescriptionExpanded = false;
  bool _isCreatingSession = false;

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

  // Opens external links using the system browser/app.
  Future<void> _openLink(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No s\'ha pogut obrir l\'enllaç')),
    );
  }

  Future<void> _handleAssistir(EventExtended event) async {
    final now = DateTime.now();
    final initialStartDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    final initialEndDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour < 23 ? now.hour + 1 : now.hour,
      now.minute,
    );
    final selectedDateTimes = await _showSessionDateTimeDialog(
      initialDateTime: initialStartDateTime,
      initialEndDateTime: initialEndDateTime,
      eventTitle: event.title,
    );

    if (selectedDateTimes == null || !mounted) {
      return;
    }

    setState(() {
      _isCreatingSession = true;
    });

    try {
      await _sessionsApi.createSession(
        CreateSessionRequest(
          event: event.code,
          startTime: selectedDateTimes.start,
          endTime: selectedDateTimes.end,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistència registrada correctament.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No s\'ha pogut registrar l\'assistència (${e.statusCode}).',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No s\'ha pogut registrar l\'assistència.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }

  Future<DateTimeRange?> _showSessionDateTimeDialog({
    required DateTime initialDateTime,
    required DateTime initialEndDateTime,
    required String eventTitle,
  }) async {
    DateTime selectedStartDate = DateTime(
      initialDateTime.year,
      initialDateTime.month,
      initialDateTime.day,
    );
    TimeOfDay selectedStartTime = TimeOfDay(
      hour: initialDateTime.hour,
      minute: initialDateTime.minute,
    );

    DateTime selectedEndDate = DateTime(
      initialEndDateTime.year,
      initialEndDateTime.month,
      initialEndDateTime.day,
    );
    TimeOfDay selectedEndTime = TimeOfDay(
      hour: initialEndDateTime.hour,
      minute: initialEndDateTime.minute,
    );

    return showDialog<DateTimeRange>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
          return DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final startDateTime = combineDateAndTime(
              selectedStartDate,
              selectedStartTime,
            );
            final endDateTime = combineDateAndTime(
              selectedEndDate,
              selectedEndTime,
            );

            return AlertDialog(
              title: const Text('Confirma l\'assistència'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_rounded),
                    title: const Text('Inici'),
                    subtitle: Text(
                      '${_formatDate(selectedStartDate)} · ${selectedStartTime.format(dialogContext)}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          confirmText: 'D\'acord',
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedStartTime,
                          initialEntryMode: TimePickerEntryMode.input,
                          confirmText: 'D\'acord',
                        );
                        if (pickedTime == null) return;
                        setDialogState(() {
                          selectedStartDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                          );
                          selectedStartTime = pickedTime;
                        });
                      },
                      child: const Text('Canvia'),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text('Final'),
                    subtitle: Text(
                      '${_formatDate(selectedEndDate)} · ${selectedEndTime.format(dialogContext)}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedEndDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          confirmText: 'D\'acord',
                        );
                        if (pickedDate == null) return;
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedEndTime,
                          initialEntryMode: TimePickerEntryMode.input,
                          confirmText: 'D\'acord',
                        );
                        if (pickedTime == null) return;
                        setDialogState(() {
                          selectedEndDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                          );
                          selectedEndTime = pickedTime;
                        });
                      },
                      child: const Text('Canvia'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel·la'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      DateTimeRange(start: startDateTime, end: endDateTime),
                    );
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd/$mm/${date.year}';
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

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreatingSession
                        ? null
                        : () => _handleAssistir(event),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: const Color.fromARGB(255, 202, 3, 3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isCreatingSession
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Assistir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
