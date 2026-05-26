import 'package:flutter/material.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/api/api_error_utils.dart';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/api/sessions_api.dart';
import 'package:agendat/core/mappers/session_mapper.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/invitations_query.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/widgets/main_app_bar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/core/widgets/section_card.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/events/presentation/widgets/info_row.dart';
import 'package:agendat/features/events/presentation/widgets/link_tile.dart';
import 'package:agendat/features/events/presentation/widgets/invite_friends_bottom_sheet.dart';
import 'package:agendat/features/events/presentation/widgets/session_picker_dialog.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_section.dart';
import 'package:agendat/core/services/google_calendar_service.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/l10n/app_localizations.dart';

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
  bool _isPreparingInvitation = false;

  bool get _isAuthenticated =>
      currentAuthToken != null && currentAuthToken!.trim().isNotEmpty;

  /// Un esdeveniment admet invitacions sempre que tingui dates conegudes i la
  /// data de fi (o de inici, si no n'hi ha de fi) encara no hagi passat.
  bool _canInviteToEvent(EventExtended event) {
    final reference = event.endDate ?? event.startDate;
    if (reference == null) return false;
    final today = DateUtils.dateOnly(DateTime.now());
    return !DateUtils.dateOnly(reference).isBefore(today);
  }

  bool get _addToGoogleCalendar =>
      (currentLoggedInUser?['calendar_sync_allowed'] as bool?) ?? true;

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  AppLocalizations get l10n => AppLocalizations.of(context);

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
    _eventsQuery.translatedContentRevisionListenable.addListener(
      _onTranslatedContentChanged,
    );
    _eventFuture = _eventsQuery.getEventByCode(widget.eventCode);
  }

  @override
  void dispose() {
    _eventsQuery.translatedContentRevisionListenable.removeListener(
      _onTranslatedContentChanged,
    );
    super.dispose();
  }

  void _retryLoad() {
    setState(() {
      _eventFuture = _eventsQuery.getEventByCode(
        widget.eventCode,
        forceRefresh: true,
      );
    });
  }

  void _onTranslatedContentChanged() {
    if (!mounted) return;
    setState(() {
      _eventFuture = _eventsQuery.getEventByCode(
        widget.eventCode,
        forceRefresh: true,
      );
    });
  }

  void _handleViewOnMap(EventExtended event) {
    if (!event.hasCoordinates) return;
    FeatureNavigation.openEventOnMap(
      context,
      eventCode: event.code,
      latitude: event.latitude!,
      longitude: event.longitude!,
      filterDate: event.startDate,
    );
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
      AppSnackBar.show(context, l10n.sessionBeforeEventStart);
      return;
    }

    if (eventEndDate != null && selectedStartDate.isAfter(eventEndDate)) {
      AppSnackBar.show(context, l10n.sessionAfterEventEnd);
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
          final calendarSuccess = await _googleCalendarService
              .createCalendarEvent(
                accessToken: accessToken,
                eventTitle: '${event.title}',
                startDateTime: selectedDateTime,
                endDateTime: endDateTime,
                description: l10n.attendanceCalendarSyncDescription,
              );

          if (!calendarSuccess && mounted) {
            AppSnackBar.show(
              context,
              l10n.attendanceCalendarSyncPartial,
              duration: const Duration(seconds: 3),
            );
          }
        }
      }

      if (!mounted) return;
      AppSnackBar.show(context, l10n.attendanceRegistered, isError: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        userMessageFromApiException(e, fallback: l10n.attendanceRegisterFailed),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        userMessageFromError(e, fallback: l10n.attendanceRegisterFailed),
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
                    title: Text(AppLocalizations.of(context).date),
                    subtitle: Text(_formatDate(selectedStartDate)),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          confirmText: AppLocalizations.of(context).confirm,
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
                      child: Text(AppLocalizations.of(context).change),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.access_time_rounded,
                      color: Color.fromARGB(255, 175, 40, 40),
                    ),
                    title: Text(AppLocalizations.of(context).time),
                    subtitle: Text(selectedStartTime.format(dialogContext)),
                    trailing: TextButton(
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                          context: dialogContext,
                          initialTime: selectedStartTime,
                          initialEntryMode: TimePickerEntryMode.input,
                          confirmText: AppLocalizations.of(context).confirm,
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
                      child: Text(AppLocalizations.of(context).change),
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
                  child: Text(AppLocalizations.of(context).cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(startDateTime);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 175, 40, 40),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context).confirm),
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

  String _localizedDateRange(Event event) {
    final start = EventTextUtils.formatDisplayDate(event.startDate);
    final end = EventTextUtils.formatDisplayDate(event.endDate);
    if (start == null && end == null) return l10n.toBeDetermined;
    if (start != null && end != null && start == end) return start;
    if (start != null && end != null) return '$start - $end';
    if (start != null) return '$start - ${l10n.toBeDetermined}';
    return '${l10n.toBeDetermined} - $end';
  }

  String _localizedPrivacy(Event event) {
    return event.isPrivate ? l10n.privateEvent : l10n.publicEvent;
  }

  String? _localizedLocation(Event event) {
    final parts = [
      EventTextUtils.labelOrNull(event.municipi),
      EventTextUtils.labelOrNull(event.provincia),
    ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  // ---------------------------------------------------------------------------
  // Flux "Convidar"
  // ---------------------------------------------------------------------------

  Future<void> _handleConvidar(EventExtended event) async {
    final l10n = AppLocalizations.of(context);
    if (_isPreparingInvitation) return;

    if (!_isAuthenticated) {
      AppSnackBar.show(context, l10n.loginRequiredToManageInvitations);
      return;
    }

    if (!_canInviteToEvent(event)) {
      AppSnackBar.show(context, l10n.cannotInviteToEvent);
      return;
    }

    setState(() => _isPreparingInvitation = true);
    try {
      final pickerResult = await SessionPickerDialog.show(
        context: context,
        event: event,
      );
      if (pickerResult == null || !mounted) return;

      Session? session;
      switch (pickerResult) {
        case SessionPickerExisting(session: final existingSession):
          session = existingSession;
        case SessionPickerCreateNew():
          session = await _createSessionForInvitation(event);
      }

      if (session == null || !mounted) return;

      final result = await InviteFriendsBottomSheet.show(
        context: context,
        event: event,
        session: session,
      );
      if (result == null || !mounted) return;

      _showInvitationSummary(result);
    } finally {
      if (mounted) {
        setState(() => _isPreparingInvitation = false);
      }
    }
  }

  /// Crea silenciosament una sessió per a l'usuari emissor (en el context del
  /// flux "Convidar"): mostra el datetime picker reutilitzat del flux
  /// "Assistir", valida les dates contra l'esdeveniment i fa POST a
  /// `/api/sessions/`. Retorna la sessió creada o `null` si l'usuari cancel·la
  /// o si hi ha un error (en aquest últim cas, ja s'ha mostrat un snackbar).
  Future<Session?> _createSessionForInvitation(EventExtended event) async {
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
    if (selectedDateTime == null || !mounted) return null;

    final selectedStartDate = DateUtils.dateOnly(selectedDateTime);
    final eventEndDate = event.endDate == null
        ? eventStartDate
        : DateUtils.dateOnly(event.endDate!);

    if (eventStartDate != null && selectedStartDate.isBefore(eventStartDate)) {
      AppSnackBar.show(
        context,
        AppLocalizations.of(context).sessionBeforeEventStart,
      );
      return null;
    }
    if (eventEndDate != null && selectedStartDate.isAfter(eventEndDate)) {
      AppSnackBar.show(
        context,
        AppLocalizations.of(context).sessionAfterEventEnd,
      );
      return null;
    }

    try {
      final endDateTime = selectedDateTime.add(const Duration(hours: 1));
      final dto = await _sessionsApi.createSession(
        CreateSessionRequest(
          event: event.code,
          startTime: selectedDateTime,
          endTime: endDateTime,
        ),
      );
      _sessionsQuery.invalidateAll();
      _sessionsQuery.invalidateEvent(event.code);
      return dto.toDomain();
    } on ApiException catch (e) {
      if (!mounted) return null;
      AppSnackBar.show(
        context,
        userMessageFromApiException(
          e,
          fallback: AppLocalizations.of(context).createInvitationSessionFailed,
        ),
      );
      return null;
    } catch (_) {
      if (!mounted) return null;
      AppSnackBar.show(
        context,
        AppLocalizations.of(context).createInvitationSessionFailed,
      );
      return null;
    }
  }

  void _showInvitationSummary(InviteFriendsResult result) {
    if (result.totalRequested == 0) return;

    final successes = result.successes.length;
    final errors = result.errors;

    if (errors.isEmpty) {
      AppSnackBar.show(
        context,
        successes == 1
            ? AppLocalizations.of(context).invitationSentSuccessfully
            : AppLocalizations.of(
                context,
              ).invitationSummaryCounts(successes, errors.length),
        isError: false,
      );
      return;
    }

    // Hi ha errors: si tots són del mateix tipus i clarament identificables,
    // mostrem un text concret; si no, obrim un diàleg amb el detall per amic.
    if (successes == 0 && errors.length == 1) {
      AppSnackBar.show(context, _friendlySendErrorMessage(errors.first.result));
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).sendSummaryTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(
                    context,
                  ).invitationSummaryCounts(successes, errors.length),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: errors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = errors[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                        ),
                        title: Text(entry.friend.displayName),
                        subtitle: Text(_friendlySendErrorMessage(entry.result)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context).close),
            ),
          ],
        );
      },
    );
  }

  /// Tradueix un [SendInvitationResult] al text exacte de les user stories.
  String _friendlySendErrorMessage(SendInvitationResult result) {
    switch (result) {
      case SendInvitationSuccess():
        return AppLocalizations.of(context).ok;
      case SendInvitationUnauthorized():
        return AppLocalizations.of(context).loginRequiredToManageInvitations;
      case SendInvitationInvalidRecipient():
        return AppLocalizations.of(context).inviteInvalidRecipient;
      case SendInvitationEventNotInvitable():
        return AppLocalizations.of(context).cannotInviteToEvent;
      case SendInvitationDuplicate():
        return AppLocalizations.of(context).inviteAlreadySent;
      case SendInvitationFailure(:final message):
        return message ?? AppLocalizations.of(context).inviteSendFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: MainAppBar(title: l10n.detailsTitle),
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
                      userMessageFromError(
                        snapshot.error!,
                        fallback: l10n.loadEventFailed,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryLoad,
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          final event = snapshot.data!;
          final displayDateRange = _localizedDateRange(event);
          final displayLocation = _localizedLocation(event);
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
                    title: l10n.descriptionLabel,
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
                  title: l10n.eventInformationTitle,
                  content: Column(
                    children: [
                      InfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: l10n.date,
                        value: displayDateRange,
                      ),
                      if (_hasText(event.schedule))
                        InfoRow(
                          icon: Icons.access_time_rounded,
                          label: l10n.horari,
                          value: event.schedule!.trim(),
                        ),

                      InfoRow(
                        icon: Icons.lock_outline_rounded,
                        label: l10n.privacy,
                        value: _localizedPrivacy(event),
                      ),

                      InfoRow(
                        icon: Icons.euro_rounded,
                        label: l10n.price,
                        value: event.free ? l10n.free : l10n.paid,
                      ),

                      if (_hasText(event.modality))
                        InfoRow(
                          icon: Icons.info_outline_rounded,
                          label: l10n.modalitat,
                          value: event.modality!.trim(),
                        ),

                      if (_hasText(event.address))
                        InfoRow(
                          icon: Icons.location_on_rounded,
                          label: l10n.address,
                          value: event.address!.trim(),
                        ),

                      if (displayLocation != null)
                        InfoRow(
                          icon: Icons.map_rounded,
                          label: l10n.location,
                          value: displayLocation,
                        ),
                    ],
                  ),
                ),

                if (_parseUrl(event.url_activity) != null ||
                    _parseUrl(event.url_locality) != null ||
                    _parseUrl(event.url_ticket) != null)
                  SectionCard(
                    title: l10n.interestingLinksTitle,
                    content: Column(
                      children: [
                        if (_parseUrl(event.url_activity) != null)
                          LinkTile(
                            label: l10n.activityWebsite,
                            uri: _parseUrl(event.url_activity)!,
                          ),
                        if (_parseUrl(event.url_locality) != null)
                          LinkTile(
                            label: l10n.localityWebsite,
                            uri: _parseUrl(event.url_locality)!,
                          ),
                        if (_parseUrl(event.url_ticket) != null)
                          LinkTile(
                            label: l10n.tickets,
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
                if (event.hasCoordinates) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleViewOnMap(event),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: const Color.fromARGB(255, 202, 3, 3),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 202, 3, 3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(
                        l10n.viewOnMap,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
                        : Text(
                            l10n.attendButton,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildConvidarButton(event),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConvidarButton(EventExtended event) {
    final l10n = AppLocalizations.of(context);
    final canInvite = _canInviteToEvent(event);
    final isBusy = _isPreparingInvitation;
    final isEnabled = canInvite && !isBusy;

    final button = SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isEnabled ? () => _handleConvidar(event) : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: const Color.fromARGB(255, 202, 3, 3),
          side: BorderSide(
            color: canInvite
                ? const Color.fromARGB(255, 202, 3, 3)
                : Colors.grey.shade400,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: isBusy
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(255, 202, 3, 3),
                  ),
                ),
              )
            : const Icon(Icons.group_add_rounded),
        label: Text(
          l10n.inviteButton,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );

    if (canInvite) return button;

    return Tooltip(
      message: l10n.cannotInviteToEvent,
      triggerMode: TooltipTriggerMode.tap,
      child: button,
    );
  }
}
