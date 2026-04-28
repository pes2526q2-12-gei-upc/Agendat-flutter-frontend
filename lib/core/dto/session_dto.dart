class SessionDto {
  final int id;
  final String event;
  final String user;
  final String startTime;
  final String? endTime;

  const SessionDto({
    required this.id,
    required this.event,
    required this.user,
    required this.startTime,
    this.endTime,
  });

  factory SessionDto.fromJson(Map<String, dynamic> json) {
    return SessionDto(
      id: (json['id'] as num).toInt(),
      event: (json['event'] ?? '').toString().trim(),
      user: (json['user'] ?? '').toString().trim(),
      startTime: (json['start_time'] ?? '').toString().trim(),
      endTime: json['end_time']?.toString().trim(),
    );
  }
}
