import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/widgets/mainAppBar.dart';
import 'package:agendat/features/events/presentation/screens/eventView.dart';
import 'package:flutter/material.dart';

enum _AgendaView { calendar, list }

class AgendaListScreen extends StatefulWidget {
  const AgendaListScreen({super.key});

  @override
  State<AgendaListScreen> createState() => _AgendaListScreenState();
}

class _AgendaListScreenState extends State<AgendaListScreen> {
  static const Color _kAccentRed = Color.fromARGB(255, 152, 38, 30);

  final EventsQuery _eventsQuery = EventsQuery();
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _eventsQuery.getEvents();
  }

  void _refresh() {
    _eventsQuery.invalidate();
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
                Expanded(child: _buildBody(snapshot)),
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
        selected: const {_AgendaView.list},
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
          if (selection.first == _AgendaView.calendar) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildBody(AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              Text(
                'No s\'ha pogut carregar la llista.\n${snapshot.error}',
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

    final events = _sortedEvents(snapshot.data ?? const []);
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.view_agenda_outlined, size: 52, color: _kAccentRed),
              SizedBox(height: 12),
              Text(
                'No hi ha esdeveniments per mostrar a la llista.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: events.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 16) : const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSectionTitle('Esdeveniments', events.length);
        }
        return _buildListEventCard(events[index - 1]);
      },
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEDEE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: _kAccentRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListEventCard(Event event) {
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
                builder: (_) => EventScreen(eventCode: event.code),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDateTimeLabel(event.startDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
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
