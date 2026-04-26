import 'dart:convert';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/session_dto.dart';

class CreateSessionRequest {
  CreateSessionRequest({
    required this.event,
    required this.startTime,
    required this.endTime,
  });

  final String event;
  final DateTime startTime;
  final DateTime endTime;

  Map<String, dynamic> toJson() {
    // Send UTC timestamps to avoid timezone ambiguity across web/mobile.
    return <String, dynamic>{
      'event': event,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
    };
  }
}

class SessionsApi {
  static const String _path = '/api/sessions/';

  Future<SessionDto> createSession(CreateSessionRequest request) async {
    final response = await ApiClient.postJson(
      _path,
      body: request.toJson(),
      expectedStatusCode: 201,
    );

    final decoded = ApiClient.decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected API response format');
    }

    return SessionDto.fromJson(decoded);
  }

  Future<List<SessionDto>> fetchSessions() async {
    final response = await ApiClient.get(_path);
    final decoded = jsonDecode(response.body) as dynamic;

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SessionDto.fromJson)
          .toList();
    }

    throw const FormatException(
      'Expected a list of sessions in the API response',
    );
  }
}
