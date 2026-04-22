import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/features/agenda/presentation/screens/agendaDetail.dart';
import 'package:agendat/features/agenda/presentation/screens/agendaList.dart';
import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

enum _AgendaView { calendar, list }

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _kAccentRed = Color.fromARGB(255, 152, 38, 30);

  final EventsQuery _eventsQuery = EventsQuery.instance;

  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _eventsQuery.getEvents();
  }

  void _refresh() {
    _eventsQuery.invalidateLists();
    setState(() {
      _eventsFuture = _eventsQuery.getEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(title: "Agenda't"),
      backgroundColor: const Color(0xFFF7F4F2),
      body: SafeArea(
        child: FutureBuilder<List<Event>>(
          future: _eventsFuture,
          builder: (context, snapshot) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildViewSwitch(),
                ),
                Expanded(child: _buildBody(context, snapshot)),
              ],
            );
          },
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
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error);
    }

    final events = _sortedEvents(snapshot.data ?? const []);
    if (events.isEmpty) {
      return _buildEmptyState();
    }

    return _buildCalendarView(context, events);
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 52,
              color: _kAccentRed,
            ),
            const SizedBox(height: 12),
            Text(
              'No hi ha esdeveniments per mostrar al calendari.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(BuildContext context, List<Event> events) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: _buildMonthGrid(context, events),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, List<Event> events) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final totalDayCells = (firstWeekday - 1) + daysInMonth;
    final weekRows = (totalDayCells / 7).ceil();

    const dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

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
          Text(
            '${<String>["Gener", "Febrer", "Març", "Abril", "Maig", "Juny", "Juliol", "Agost", "Setembre", "Octubre", "Novembre", "Desembre"][now.month - 1]} ${now.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                DateTime(now.year, now.month, dayNumber),
              );
              final dayEvents = _eventsForDate(events, date);
              final hasEvents = dayEvents.isNotEmpty;
              final isToday = DateUtils.isSameDay(DateTime.now(), date);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AgendaDetailScreen(date: date, events: events),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFFFF3F4)
                          : Colors.transparent,
                      border: Border.all(
                        color: isToday ? _kAccentRed : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isToday
                                  ? _kAccentRed
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                        if (hasEvents)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _kAccentRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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

  List<Event> _sortedEvents(List<Event> events) {
    final sorted = [...events];
    sorted.sort((left, right) {
      final leftDate =
          left.startDate ??
          left.endDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightDate =
          right.startDate ??
          right.endDate ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final byDate = leftDate.compareTo(rightDate);
      if (byDate != 0) return byDate;
      return left.title.toLowerCase().compareTo(right.title.toLowerCase());
    });
    return sorted;
  }

  List<Event> _eventsForDate(List<Event> events, DateTime date) {
    return events.where((event) => _eventMatchesDate(event, date)).toList();
  }

  bool _eventMatchesDate(Event event, DateTime date) {
    final selected = DateUtils.dateOnly(date.toLocal());
    final start = event.startDate == null
        ? null
        : DateUtils.dateOnly(event.startDate!.toLocal());
    final end = event.endDate == null
        ? start
        : DateUtils.dateOnly(event.endDate!.toLocal());

    if (start == null && end == null) {
      return false;
    }

    final rangeStart = start ?? end!;
    final rangeEnd = end ?? rangeStart;
    return !selected.isBefore(rangeStart) && !selected.isAfter(rangeEnd);
  }
}
