class Session {
  const Session({
    required this.id,
    required this.event,
    required this.user,
    required this.startTime,
    this.endTime,
  });

  final int id;
  final String event;
  final String user;
  final DateTime startTime;
  final DateTime? endTime;
}
