import 'package:flutter/material.dart';

import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/l10n/app_localizations.dart';

class ProfileAttendedSessionsTab extends StatelessWidget {
  const ProfileAttendedSessionsTab({
    super.key,
    this.isOwnProfile = true,
    required this.sessionsQuery,
    required this.eventsQuery,
    required this.onOpenSession,
  });

  /// Només es mostra aquest contingut des del perfil propi (`profile.dart`).
  final bool isOwnProfile;
  final SessionsQuery sessionsQuery;
  final EventsQuery eventsQuery;
  final ValueChanged<Session> onOpenSession;

  static List<Session> sortedSessions(List<Session> sessions) {
    final sorted = [...sessions];
    sorted.sort((left, right) {
      final byDate = right.startTime.compareTo(left.startTime);
      if (byDate != 0) return byDate;
      return left.event.toLowerCase().compareTo(right.event.toLowerCase());
    });
    return sorted;
  }

  static String formatSessionDateTime(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();
    final day = localDateTime.day.toString().padLeft(2, '0');
    final month = localDateTime.month.toString().padLeft(2, '0');
    final year = localDateTime.year.toString();
    final hour = localDateTime.hour.toString().padLeft(2, '0');
    final minute = localDateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year · $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!isOwnProfile) {
      return _tabEmpty(
        l10n.attendancesOnlyOwnProfile,
        Icons.event_outlined,
      );
    }

    return FutureBuilder<List<Session>>(
      future: sessionsQuery.getSessions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _tabEmpty(
            l10n.loadAttendancesFailed,
            Icons.error_outline,
          );
        }

        final sessions = sortedSessions(snapshot.data ?? const []);
        if (sessions.isEmpty) {
          return _tabEmpty(
            l10n.noAttendancesYet,
            Icons.event_outlined,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_available, color: Colors.grey.shade600),
              title: _SessionEventTitle(
                eventsQuery: eventsQuery,
                eventCode: session.event,
              ),
              subtitle: Text(formatSessionDateTime(session.startTime)),
              onTap: () => onOpenSession(session),
            );
          },
        );
      },
    );
  }
}

Widget _tabEmpty(String message, IconData icon) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),
      ],
    ),
  );
}

class _SessionEventTitle extends StatelessWidget {
  const _SessionEventTitle({
    required this.eventsQuery,
    required this.eventCode,
  });

  final EventsQuery eventsQuery;
  final String eventCode;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventExtended>(
      future: eventsQuery.getEventByCode(eventCode),
      builder: (context, snapshot) {
        final title = snapshot.data?.title.trim();
        final display = (title == null || title.isEmpty) ? eventCode : title;
        return Text(
          display,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
