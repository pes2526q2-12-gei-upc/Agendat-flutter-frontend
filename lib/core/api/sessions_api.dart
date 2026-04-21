import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/session_dto.dart';

class CreateSessionRequest {
  CreateSessionRequest({
    required this.event,
    required this.user,
    required this.startTime,
    this.endTime,
  });

  final String event;
  final String user;
  final DateTime startTime;
  final DateTime? endTime;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'event': event,
      'user': user,
      'start_time': startTime.toIso8601String(),
    };

    if (endTime != null) {
      payload['end_time'] = endTime!.toIso8601String();
    }

    return payload;
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
}
