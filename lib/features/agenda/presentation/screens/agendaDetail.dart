import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:flutter/material.dart';

class AgendaDetailScreen extends StatefulWidget {
  static const Color _kAccentRed = Color.fromARGB(255, 152, 38, 30);
  static final EventsQuery _eventsQuery = EventsQuery.instance;

  final DateTime date;
  final List<Session> sessions;

  const AgendaDetailScreen({
    super.key,
    required this.date,
    required this.sessions,
  });

  @override
  State<AgendaDetailScreen> createState() => _AgendaDetailScreenState();
}

class _AgendaDetailScreenState extends State<AgendaDetailScreen> {
  static const Color _kAccentRed = AgendaDetailScreen._kAccentRed;
  final SessionsQuery _sessionsQuery = SessionsQuery.instance;
  late List<Session> _sessions;

  @override
  void initState() {
    super.initState();
    _sessions = List<Session>.of(widget.sessions);
  }

  @override
  Widget build(BuildContext context) {
    final normalizedDate = DateUtils.dateOnly(widget.date);
    final daySessions = _sessions
        .where((session) => _sessionMatchesDate(session, normalizedDate))
        .toList();
    daySessions.sort((left, right) {
      return left.startTime.compareTo(right.startTime);
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kAccentRed),
        title: Text(
          _formatSelectedDate(normalizedDate),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF7F4F2),
      body: SafeArea(
        child: daySessions.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 52,
                        color: _kAccentRed,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No tens cap esdeveniment programat per aquest dia.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: AppScreenSpacing.content,
                itemCount: daySessions.length + 1,
                separatorBuilder: (_, index) => index == 0
                    ? const SizedBox(height: 16)
                    : const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sessions',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEDEE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${daySessions.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kAccentRed,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  final session = daySessions[index - 1];
                  return _buildSessionCard(context, session);
                },
              ),
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, Session session) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EventScreen(eventCode: session.event),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF2D6D9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE3E6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_rounded,
                    color: _kAccentRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _formatDateTimeLabel(session.startTime),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildDeleteSessionButton(session),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildEventTitle(session.event),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteSessionButton(Session session) {
    return IconButton(
      tooltip: 'Eliminar sessió',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: const Icon(Icons.delete_outline_rounded, color: _kAccentRed),
      onPressed: () => _confirmDeleteSession(session),
    );
  }

  Future<void> _confirmDeleteSession(Session session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar sessió'),
          content: const Text('Vols eliminar aquesta sessió de l’agenda?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel·lar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: _kAccentRed),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    await _sessionsQuery.deleteSession(session.id);
    setState(() {
      _sessions.removeWhere((item) => item.id == session.id);
    });
  }

  bool _sessionMatchesDate(Session session, DateTime date) {
    final selected = DateUtils.dateOnly(date.toLocal());
    final sessionDate = DateUtils.dateOnly(session.startTime.toLocal());
    return DateUtils.isSameDay(sessionDate, selected);
  }

  Widget _buildEventTitle(String eventCode) {
    return FutureBuilder<EventExtended>(
      future: AgendaDetailScreen._eventsQuery.getEventByCode(eventCode),
      builder: (context, snapshot) {
        final title = snapshot.data?.title.trim();
        final display = (title == null || title.isEmpty) ? eventCode : title;

        return Text(
          display,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        );
      },
    );
  }

  String _formatSelectedDate(DateTime date) {
    const weekdayNames = <String>['Dl', 'Dt', 'Dc', 'Dj', 'Dv', 'Ds', 'Dg'];
    const monthNames = <String>[
      'gener',
      'febrer',
      'març',
      'abril',
      'maig',
      'juny',
      'juliol',
      'agost',
      'setembre',
      'octubre',
      'novembre',
      'desembre',
    ];

    final weekday = weekdayNames[date.weekday - 1];
    final month = EventTextUtils.capitalizeFirst(monthNames[date.month - 1]);
    return '$weekday, ${date.day} $month ${date.year}';
  }

  String _formatDateTimeLabel(DateTime? dateTime) {
    if (dateTime == null) {
      return 'Data i hora per determinar';
    }

    final localDateTime = dateTime.toLocal();

    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year.toString();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }
}
