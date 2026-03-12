import 'dart:convert';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:agendat/features/auth/data/models/login_user_request.dart';
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
  final uri = Uri.parse('${getBaseUrl()}/api/users/');
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

sealed class LoginUserResult {}

class LoginUserSuccess extends LoginUserResult {
  LoginUserSuccess({this.statusCode = 200, this.body});
  final int statusCode;
  final Map<String, dynamic>? body;
}

class LoginUserFailure extends LoginUserResult {
  LoginUserFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// Dades de l'usuari actualment autenticat (durant l'execució de l'app).
Map<String, dynamic>? currentLoggedInUser;

void setCurrentLoggedInUser(Map<String, dynamic>? userJson) {
  currentLoggedInUser = userJson;
}

/// Crida POST /api/users/login/ per iniciar sessió.
Future<LoginUserResult> loginUser(LoginUserRequest request) async {
  final uri = Uri.parse('${getBaseUrl()}/api/users/login/');
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
      return LoginUserSuccess(statusCode: response.statusCode, body: decoded);
    }
    return LoginUserFailure(statusCode: response.statusCode, body: decoded);
  } catch (e) {
    return LoginUserFailure(statusCode: -1, error: e);
  }
}
