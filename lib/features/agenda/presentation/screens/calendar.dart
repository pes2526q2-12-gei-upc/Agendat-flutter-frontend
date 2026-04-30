import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/agenda/presentation/screens/agendaDetail.dart';
import 'package:agendat/features/agenda/presentation/screens/agendaList.dart';
import 'package:agendat/main.dart' show kAgendaTabIndex, rootTabIndexNotifier;
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _AgendaView { calendar, list }

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _kAccentRed = Color.fromARGB(255, 152, 38, 30);
  static const Color _kSessionDayRed = Color(0xFFFFDDE0);
  static const List<String> _monthNames = [
    'Gener',
    'Febrer',
    'Març',
    'Abril',
    'Maig',
    'Juny',
    'Juliol',
    'Agost',
    'Setembre',
    'Octubre',
    'Novembre',
    'Desembre',
  ];

  final SessionsQuery _sessionsQuery = SessionsQuery.instance;

  late Future<List<Session>> _sessionsFuture;
  int _monthOffset = 0;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _sessionsQuery.getSessions(forceRefresh: true);
    rootTabIndexNotifier.addListener(_onRootTabChanged);
  }

  @override
  void dispose() {
    rootTabIndexNotifier.removeListener(_onRootTabChanged);
    super.dispose();
  }

  void _onRootTabChanged() {
    if (rootTabIndexNotifier.value == kAgendaTabIndex) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _sessionsFuture = _sessionsQuery.getSessions(forceRefresh: true);
    });
    try {
      await _sessionsFuture;
    } catch (_) {
      // The FutureBuilder displays the error state for `_sessionsFuture`.
      // Swallow refresh errors here to avoid uncaught async exceptions when
      // pull-to-refresh or tab changes trigger a reload.
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _monthOffset += delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: "Agenda"),
      backgroundColor: AppThemeTokens.screenBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Session>>(
            future: _sessionsFuture,
            builder: (context, snapshot) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppScreenSpacing.horizontal,
                      AppScreenSpacing.top,
                      AppScreenSpacing.horizontal,
                      0,
                    ),
                    child: _buildViewSwitch(),
                  ),
                  Expanded(child: _buildBody(context, snapshot)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildViewSwitch() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: SegmentedButton<_AgendaView>(
        segments: const [
          ButtonSegment<_AgendaView>(
            value: _AgendaView.calendar,
            icon: Icon(Icons.calendar_month_rounded),
            label: Text('Calendari'),
          ),
          ButtonSegment<_AgendaView>(
            value: _AgendaView.list,
            icon: Icon(Icons.view_agenda_rounded),
            label: Text('Llista'),
          ),
        ],
        selected: const {_AgendaView.calendar},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const BorderSide(color: _kAccentRed, width: 1.4);
            }
            return BorderSide(color: Colors.grey.shade300);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? _kAccentRed
                : Colors.grey.shade700;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? const Color(0xFFFFEDEE)
                : Colors.white;
          }),
        ),
        onSelectionChanged: (selection) {
          if (selection.first == _AgendaView.list) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AgendaListScreen()),
            ).then((_) {
              if (mounted) {
                _refresh();
              }
            });
          }
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncSnapshot<List<Session>> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }

    final sessions = _sortedSessions(snapshot.data ?? const []);
    return _buildCalendarView(context, sessions);
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              'No s\'ha pogut carregar l\'agenda.\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<Session> sessions) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppScreenSpacing.horizontal,
          AppScreenSpacing.top,
          AppScreenSpacing.horizontal,
          12,
        ),
        child: _buildMonthGrid(context, sessions),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, List<Session> sessions) {
    final baseDate = DateTime.now();
    final monthDate = DateTime(baseDate.year, baseDate.month + _monthOffset, 1);
    final firstDayOfMonth = monthDate;
    final lastDayOfMonth = DateTime(monthDate.year, monthDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final totalDayCells = (firstWeekday - 1) + daysInMonth;
    final weekRows = (totalDayCells / 7).ceil();

    const dayLabels = ['DL', 'DM', 'DC', 'DJ', 'DV', 'DS', 'DG'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left_rounded),
                color: _kAccentRed,
              ),
              Expanded(
                child: Text(
                  '${_monthNames[monthDate.month - 1]} ${monthDate.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right_rounded),
                color: _kAccentRed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: 7 + (weekRows * 7),
            itemBuilder: (context, index) {
              if (index < 7) {
                return Center(
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                );
              }

              final dayIndex = index - 7;
              final dayNumber = dayIndex - (firstWeekday - 1) + 1;

              if (dayIndex < firstWeekday - 1 || dayNumber > daysInMonth) {
                return const SizedBox();
              }

              final date = DateUtils.dateOnly(
                DateTime(monthDate.year, monthDate.month, dayNumber),
              );
              final daySessions = _sessionsForDate(sessions, date);
              final hasEvents = daySessions.isNotEmpty;
              final isToday = DateUtils.isSameDay(DateTime.now(), date);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AgendaDetailScreen(
                          date: date,
                          sessions: daySessions,
                        ),
                      ),
                    ).then((_) {
                      if (mounted) {
                        _refresh();
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? _kAccentRed
                          : (hasEvents ? _kSessionDayRed : Colors.transparent),
                      border: Border.all(color: Colors.transparent, width: 0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? Colors.white
                              : (hasEvents
                                    ? _kAccentRed
                                    : Colors.grey.shade700),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Session> _sortedSessions(List<Session> sessions) {
    final sorted = [...sessions];
    sorted.sort((left, right) {
      final leftDate = left.startTime;
      final rightDate = right.startTime;
      final byDate = leftDate.compareTo(rightDate);
      if (byDate != 0) return byDate;
      return left.event.compareTo(right.event);
    });
    return sorted;
  }

  List<Session> _sessionsForDate(List<Session> sessions, DateTime date) {
    return sessions
        .where((session) => _sessionMatchesDate(session, date))
        .toList();
  }

  bool _sessionMatchesDate(Session session, DateTime date) {
    final selected = DateUtils.dateOnly(date.toLocal());
    final sessionDate = DateUtils.dateOnly(session.startTime.toLocal());
    return DateUtils.isSameDay(selected, sessionDate);
  }
}
