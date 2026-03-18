import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/services/token_storage.dart';
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

Future<void> setCurrentLoggedInUser(Map<String, dynamic>? userJson) async {
  currentLoggedInUser = userJson;
  // Persist user data to secure storage
  await TokenStorage.writeUser(userJson);
}

Future<void> setCurrentAuthToken(String? token) async {
  currentAuthToken = token;
  ApiClient.setAuthToken(token);
  await TokenStorage.write(token);
}

/// Tanca la sessió local: esborra l'usuari i el token d'autenticació.
Future<void> logout() async {
  currentLoggedInUser = null;
  currentAuthToken = null;
  ApiClient.setAuthToken(null);
  await TokenStorage.clear();
}

/// Restaura la sessió des del disc en arrencar l'app.
/// Retorna `true` si hi havia un token desat (l'usuari pot saltar el login).
Future<bool> restoreSession() async {
  final token = await TokenStorage.read();
  if (token == null) {
    return false;
  }

  final userJson = await TokenStorage.readUser();
  if (userJson != null) {
    currentLoggedInUser = userJson;
  }

  currentAuthToken = token;
  ApiClient.setAuthToken(token);

  return true;
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
      await setCurrentLoggedInUser(user);
    } else {
      await setCurrentLoggedInUser(null);
    }
    await setCurrentAuthToken(token);
    return LoginUserSuccess(statusCode: response.statusCode, body: decoded);
  } on ApiException catch (e) {
    return LoginUserFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return LoginUserFailure(statusCode: -1, error: e);
  }
}
