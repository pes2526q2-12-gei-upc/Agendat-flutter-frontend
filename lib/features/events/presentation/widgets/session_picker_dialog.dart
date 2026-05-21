import 'package:flutter/material.dart';

import 'package:agendat/core/api/api_error_utils.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/sessions_query.dart';

/// Resultat retornat per [SessionPickerDialog.show].
sealed class SessionPickerResult {
  const SessionPickerResult();
}

/// L'usuari ha triat una sessió ja existent.
class SessionPickerExisting extends SessionPickerResult {
  const SessionPickerExisting(this.session);
  final Session session;
}

/// L'usuari vol crear una sessió nova: el cridant ha d'obrir el datetime
/// picker existent (compartit amb el flux "Assistir") i, després de crear
/// la sessió, continuar amb el següent pas (per exemple, mostrar el picker
/// d'amics).
class SessionPickerCreateNew extends SessionPickerResult {
  const SessionPickerCreateNew();
}

/// Diàleg que llista les sessions de l'usuari per a l'esdeveniment i ofereix
/// una opció final "Crear nova sessió". S'utilitza des de la pantalla de
/// detall d'esdeveniment quan l'usuari prem "Convidar": cal triar a quina
/// sessió van adreçades les invitacions.
class SessionPickerDialog extends StatefulWidget {
  const SessionPickerDialog({super.key, required this.event});

  final Event event;

  /// Mostra el diàleg modal. Retorna `null` si l'usuari el cancel·la.
  static Future<SessionPickerResult?> show({
    required BuildContext context,
    required Event event,
  }) {
    return showDialog<SessionPickerResult>(
      context: context,
      builder: (_) => SessionPickerDialog(event: event),
    );
  }

  @override
  State<SessionPickerDialog> createState() => _SessionPickerDialogState();
}

class _SessionPickerDialogState extends State<SessionPickerDialog> {
  static const Color _accentRed = Color.fromARGB(255, 175, 40, 40);

  final SessionsQuery _sessionsQuery = SessionsQuery.instance;

  late Future<List<Session>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = _sessionsQuery.getSessionsForEvent(
      widget.event.code,
      forceRefresh: true,
    );
  }

  void _selectExisting(Session session) {
    Navigator.of(context).pop(SessionPickerExisting(session));
  }

  void _selectCreateNew() {
    Navigator.of(context).pop(const SessionPickerCreateNew());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 255, 244, 244),
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'A quina sessió convides?',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Session>>(
          future: _sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userMessageFromError(
                      snapshot.error!,
                      fallback:
                          'No s\'han pogut carregar les teves sessions per a aquest esdeveniment.',
                    ),
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  _CreateNewSessionTile(onTap: _selectCreateNew),
                ],
              );
            }

            final sessions = _sortSessions(snapshot.data ?? const []);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Encara no tens cap sessió per aquest esdeveniment. '
                      'Crea\'n una de nova per convidar als teus amics.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _SessionTile(
                          session: session,
                          onTap: () => _selectExisting(session),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                _CreateNewSessionTile(onTap: _selectCreateNew),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _accentRed),
          child: const Text('Cancel·la'),
        ),
      ],
    );
  }

  List<Session> _sortSessions(List<Session> sessions) {
    final sorted = [...sessions];
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onTap});

  final Session session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = MaterialLocalizations.of(context);
    final start = session.startTime.toLocal();
    final dateLabel = locale.formatFullDate(start);
    final timeLabel = locale.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
      alwaysUse24HourFormat: true,
    );

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.calendar_today_rounded,
        color: Color.fromARGB(255, 175, 40, 40),
      ),
      title: Text(
        dateLabel,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('A les $timeLabel'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _CreateNewSessionTile extends StatelessWidget {
  const _CreateNewSessionTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 175, 40, 40),
            width: 1.2,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Color.fromARGB(255, 175, 40, 40),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Crea una sessió nova',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color.fromARGB(255, 175, 40, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
