import 'package:flutter/material.dart';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/api/sessions_api.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/widgets/section_card.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/events/presentation/widgets/info_row.dart';
import 'package:agendat/features/events/presentation/widgets/link_tile.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:agendat/core/services/google_calendar_service.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key, required this.eventCode});

  final String eventCode;

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final EventsQuery _eventsQuery = EventsQuery.instance;
  final SessionsQuery _sessionsQuery = SessionsQuery.instance;
  final SessionsApi _sessionsApi = SessionsApi();
  final GoogleCalendarService _googleCalendarService = GoogleCalendarService();
  late Future<EventExtended> _eventFuture;
  bool _isDescriptionExpanded = false;
  bool _isCreatingSession = false;
  bool _addToGoogleCalendar =
      true; // User preference to add event to Google Calendar

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

  Future<void> _handleAssistir(EventExtended event) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final eventStartDate = event.startDate == null
        ? null
        : DateUtils.dateOnly(event.startDate!);
    final initialDate = eventStartDate != null && eventStartDate.isAfter(today)
        ? eventStartDate
        : today;
    final initialStartDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      0,
      0,
    );
    final selectedDateTime = await _showSessionDateTimeDialog(
      initialDateTime: initialStartDateTime,
      eventTitle: event.title,
    );

    if (selectedDateTime == null || !mounted) {
      return;
    }

    final selectedStartDate = DateUtils.dateOnly(selectedDateTime);
    final eventEndDate = event.endDate == null
        ? eventStartDate
        : DateUtils.dateOnly(event.endDate!);

    if (eventStartDate != null && selectedStartDate.isBefore(eventStartDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La sessió seleccionada és anterior a l\'inici de l\'esdeveniment.',
          ),
        ),
      );
      return;
    }

    if (eventEndDate != null && selectedStartDate.isAfter(eventEndDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La sessió seleccionada és posterior al final de l\'esdeveniment.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingSession = true;
    });

    try {
      final endDateTime = selectedDateTime.add(const Duration(hours: 1));
      await _sessionsApi.createSession(
        CreateSessionRequest(
          event: event.code,
          startTime: selectedDateTime,
          endTime: endDateTime,
        ),
      );
      _sessionsQuery.invalidateAll();

      // Add event to Google Calendar if user has given permission
      if (_addToGoogleCalendar) {
        final accessToken = await _googleCalendarService.getAccessToken();
        if (accessToken != null && mounted) {
          final calendarSuccess = await _googleCalendarService.createCalendarEvent(
            accessToken: accessToken,
            eventTitle: '${event.title}',
            startDateTime: selectedDateTime,
            endDateTime: endDateTime,
            description:
                'Sessió sincronitzada automàticament des de l\'aplicació Agenda\'t',
          );

          if (!calendarSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Assistència registrada, però no s\'ha pogut afegir a Google Calendar.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Assistència registrada correctament.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final detail = e.body.trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail.isEmpty
                ? 'No s\'ha pogut registrar l\'assistència (${e.statusCode}).'
                : 'No s\'ha pogut registrar l\'assistència (${e.statusCode}): $detail',
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

  Future<DateTime?> _showSessionDateTimeDialog({
    required DateTime initialDateTime,
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

    return showDialog<DateTime>(
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

            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 255, 244, 244),
              surfaceTintColor: Colors.transparent,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFFD96B6B),
                    ),
                    title: const Text('Data'),
                    subtitle: Text(_formatDate(selectedStartDate)),
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
                        setDialogState(() {
                          selectedStartDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                          );
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 175, 40, 40),
                      ),
                      child: const Text('Canvia'),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.access_time_rounded,
                      color: Color.fromARGB(255, 175, 40, 40),
                    ),
                    title: const Text('Hora'),
                    subtitle: Text(selectedStartTime.format(dialogContext)),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedStartTime,
                          initialEntryMode: TimePickerEntryMode.input,
                          confirmText: 'D\'acord',
                          builder: (context, child) {
                            final mediaQuery = MediaQuery.of(context);
                            return MediaQuery(
                              data: mediaQuery.copyWith(
                                alwaysUse24HourFormat: true,
                              ),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );
                        if (pickedTime == null) return;
                        setDialogState(() {
                          selectedStartTime = pickedTime;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC84D4D),
                      ),
                      child: const Text('Canvia'),
                    ),
                  ),
                  const SizedBox(height: 0),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC84D4D),
                  ),
                  child: const Text('Cancel·la'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(startDateTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 175, 40, 40),
                    foregroundColor: Colors.white,
                  ),
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
          final String displayDateRange = event.displayDateRange;
          final List<String> formattedCategories = event.categories
              .map(EventTextUtils.labelOrNull)
              .whereType<String>()
              .toList();

          return SingleChildScrollView(
            padding: AppScreenSpacing.content,
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
                        value: displayDateRange,
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
}
