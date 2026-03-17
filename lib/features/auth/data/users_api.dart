import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:agendat/features/auth/data/models/login_user_request.dart';

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
  try {
    final response = await ApiClient.postJson(
      '/api/users/',
      body: request.toJson(),
      expectedStatusCode: 201,
    );
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>?
        : null;
    return CreateUserSuccess(statusCode: response.statusCode, body: decoded);
  } on ApiException catch (e) {
    return CreateUserFailure(statusCode: e.statusCode, error: e);
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
String? currentAuthToken;

/// Desa l'usuari autenticat amb JSON, potser més endavant fer-ho amb
void setCurrentLoggedInUser(Map<String, dynamic>? userJson) {
  currentLoggedInUser = userJson;
}

void setCurrentAuthToken(String? token) {
  currentAuthToken = token;
  ApiClient.setAuthToken(token);
}

/// Implementada tot i que no s'utilitza actualment. Feta pel futur.
void logout() {
  setCurrentLoggedInUser(null);
  setCurrentAuthToken(null);
}

/// Crida POST /api/users/login/ per iniciar sessió.
Future<LoginUserResult> loginUser(LoginUserRequest request) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/login/',
      body: request.toJson(),
      expectedStatusCode: 200,
    );
    // Backend returns: { "token": "...",
    //                    "user": { ... } }
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>?
        : null;
    final token = decoded?['token']?.toString();
    final user = decoded?['user'];
    if (user is Map<String, dynamic>) {
      setCurrentLoggedInUser(user);
    } else {
      setCurrentLoggedInUser(null);
    }
    setCurrentAuthToken(token);
    return LoginUserSuccess(statusCode: response.statusCode, body: decoded);
  } on ApiException catch (e) {
    return LoginUserFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return LoginUserFailure(statusCode: -1, error: e);
  }
}
