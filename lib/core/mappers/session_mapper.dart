import 'package:agendat/core/dto/session_dto.dart';
import 'package:agendat/core/models/session.dart';

extension SessionDtoMapper on SessionDto {
  Session toDomain() {
    return Session(
      id: id,
      event: event,
      user: user,
      startTime: _parseDateTime(startTime),
      endTime: _parseOptionalDateTime(endTime),
    );
  }
}

DateTime _parseDateTime(String raw) {
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _parseOptionalDateTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}
