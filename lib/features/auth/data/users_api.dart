import 'dart:convert';

import 'package:agendat/core/network/api_config.dart';
import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:http/http.dart' as http;

/// Resultat de la creació d'usuari.
sealed class CreateUserResult {}

class CreateUserSuccess extends CreateUserResult {
  CreateUserSuccess({this.statusCode = 201, this.body});
  final int statusCode;
  final Map<String, dynamic>? body;
}

class CreateUserFailure extends CreateUserResult {
  CreateUserFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// Crida POST /api/users/ per registrar un usuari nou.
Future<CreateUserResult> createUser(CreateUserRequest request) async {
  final uri = Uri.parse('$kApiBaseUrl/api/users/');
  try {
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>?
        : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CreateUserSuccess(statusCode: response.statusCode, body: decoded);
    }
    return CreateUserFailure(statusCode: response.statusCode, body: decoded);
  } catch (e) {
    return CreateUserFailure(statusCode: -1, error: e);
  }
}
