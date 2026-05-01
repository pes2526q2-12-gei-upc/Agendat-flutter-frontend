import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/core/services/token_storage.dart';
import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:agendat/features/auth/data/models/forgot_password_request.dart';
import 'package:agendat/features/auth/data/models/login_user_request.dart';
import 'package:agendat/features/auth/data/models/reset_password_request.dart';
import 'package:agendat/features/auth/data/models/signup_code_confirm_request.dart';

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

sealed class RequestSignupCodeResult {}

class RequestSignupCodeSuccess extends RequestSignupCodeResult {
  RequestSignupCodeSuccess({this.statusCode = 200, this.body});
  final int statusCode;
  final Map<String, dynamic>? body;
}

class RequestSignupCodeFailure extends RequestSignupCodeResult {
  RequestSignupCodeFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// Crida POST /api/users/signup/request-code/ per enviar el codi de registre.
Future<RequestSignupCodeResult> requestSignupCode(
  CreateUserRequest request,
) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/signup/request-code/',
      body: request.toJson(),
      expectedStatusCode: 200,
    );
    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body) as Map<String, dynamic>?
        : null;
    return RequestSignupCodeSuccess(
      statusCode: response.statusCode,
      body: decoded,
    );
  } on ApiException catch (e) {
    Map<String, dynamic>? body;
    if (e.body.isNotEmpty) {
      try {
        body = jsonDecode(e.body) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return RequestSignupCodeFailure(
      statusCode: e.statusCode,
      body: body,
      error: e,
    );
  } catch (e) {
    return RequestSignupCodeFailure(statusCode: -1, error: e);
  }
}

sealed class ConfirmSignupCodeResult {}

class ConfirmSignupCodeSuccess extends ConfirmSignupCodeResult {
  ConfirmSignupCodeSuccess({this.statusCode = 201, this.body});
  final int statusCode;
  final Map<String, dynamic>? body;
}

class ConfirmSignupCodeFailure extends ConfirmSignupCodeResult {
  ConfirmSignupCodeFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// Crida POST /api/users/signup/confirm/ per crear el compte verificat.
Future<ConfirmSignupCodeResult> confirmSignupCode(
  SignupCodeConfirmRequest request,
) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/signup/confirm/',
      body: request.toJson(),
      expectedStatusCode: 201,
    );
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
    await PushNotificationsService.instance
        .requestPermissionAndRegisterDevice();
    return ConfirmSignupCodeSuccess(
      statusCode: response.statusCode,
      body: decoded,
    );
  } on ApiException catch (e) {
    Map<String, dynamic>? body;
    if (e.body.isNotEmpty) {
      try {
        body = jsonDecode(e.body) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return ConfirmSignupCodeFailure(
      statusCode: e.statusCode,
      body: body,
      error: e,
    );
  } catch (e) {
    return ConfirmSignupCodeFailure(statusCode: -1, error: e);
  }
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
  final normalizedUser = _normalizeLoggedInUser(userJson);
  currentLoggedInUser = normalizedUser;
  await TokenStorage.writeUser(normalizedUser);
}

Map<String, dynamic>? _normalizeLoggedInUser(Map<String, dynamic>? userJson) {
  if (userJson == null) return null;

  final normalizedUser = Map<String, dynamic>.from(userJson);
  normalizedUser['calendar_sync_allowed'] =
      normalizedUser['calendar_sync_allowed'] ??
      currentLoggedInUser?['calendar_sync_allowed'] ??
      true;
  return normalizedUser;
}

Future<void> setCurrentAuthToken(String? token) async {
  currentAuthToken = token;
  ApiClient.setAuthToken(token);
  await TokenStorage.write(token);
}

/// Tanca la sessió local: esborra l'usuari i el token d'autenticació.
Future<void> logout() async {
  await PushNotificationsService.instance.unregisterDevice();
  await clearLocalSession();
}

/// Clears only local auth state without calling the backend.
Future<void> clearLocalSession() async {
  currentLoggedInUser = null;
  currentAuthToken = null;
  ApiClient.setAuthToken(null);
  await TokenStorage.clear();
}

/// Restaura la sessió des del disc en arrencar l'app.
/// Retorna `true` si hi havia un token desat (l'usuari pot saltar el login).
Future<bool> restoreSession() async {
  final token = await TokenStorage.read();
  if (token == null || token.trim().isEmpty) {
    await clearLocalSession();
    return false;
  }

  final userJson = await TokenStorage.readUser();
  if (userJson != null) {
    currentLoggedInUser = userJson;
  }

  currentAuthToken = token.trim();
  ApiClient.setAuthToken(currentAuthToken);

  final userId = _intFromValue(currentLoggedInUser?['id']);
  if (userId != null) {
    final isValid = await _validateRestoredSession(userId);
    if (!isValid) {
      await clearLocalSession();
      return false;
    }
  }

  return true;
}

int? _intFromValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return null;
}

Future<bool> _validateRestoredSession(int userId) async {
  try {
    await ApiClient.get('/api/users/$userId/');
    return true;
  } on ApiException catch (e) {
    return !isInvalidAuthTokenResponse(e);
  } catch (_) {
    return true;
  }
}

bool isInvalidAuthTokenResponse(ApiException exception) {
  if (exception.statusCode != 401 && exception.statusCode != 403) {
    return false;
  }

  final body = exception.body.toLowerCase();
  return body.contains('token') || body.contains('credentials');
}

/// Crida POST /api/users/login-with-google/ per iniciar sessió amb Google.
Future<LoginUserResult> loginWithGoogle({
  String? idToken,
  String? accessToken,
}) async {
  try {
    final body = <String, dynamic>{};
    if (idToken != null) body['id_token'] = idToken;
    if (accessToken != null) body['access_token'] = accessToken;

    final response = await ApiClient.postJson(
      '/api/users/login-with-google/',
      body: body,
      expectedStatusCode: 200,
    );
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
    await PushNotificationsService.instance
        .requestPermissionAndRegisterDevice();
    return LoginUserSuccess(statusCode: response.statusCode, body: decoded);
  } on ApiException catch (e) {
    Map<String, dynamic>? body;
    if (e.body.isNotEmpty) {
      try {
        body = jsonDecode(e.body) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return LoginUserFailure(statusCode: e.statusCode, body: body, error: e);
  } catch (e) {
    return LoginUserFailure(statusCode: -1, error: e);
  }
}

/// Crida POST /api/users/login/ per iniciar sessió.
Future<LoginUserResult> loginUser(LoginUserRequest request) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/login/',
      body: request.toJson(),
      expectedStatusCode: 200,
    );
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
    await PushNotificationsService.instance
        .requestPermissionAndRegisterDevice();
    return LoginUserSuccess(statusCode: response.statusCode, body: decoded);
  } on ApiException catch (e) {
    return LoginUserFailure(statusCode: e.statusCode, error: e);
  } catch (e) {
    return LoginUserFailure(statusCode: -1, error: e);
  }
}

// --- Forgot / reset password ---

sealed class ForgotPasswordResult {}

class ForgotPasswordSuccess extends ForgotPasswordResult {
  ForgotPasswordSuccess({this.message, this.statusCode = 200});
  final int statusCode;
  final String? message;
}

class ForgotPasswordFailure extends ForgotPasswordResult {
  ForgotPasswordFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// POST /api/users/password-reset/ — envia un codi de 6 dígits al correu.
Future<ForgotPasswordResult> forgotPassword(
  ForgotPasswordRequest request,
) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/password-reset/',
      body: request.toJson(),
      expectedStatusCode: 200,
    );
    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;
    return ForgotPasswordSuccess(
      statusCode: response.statusCode,
      message: decoded?.toString(),
    );
  } on ApiException catch (e) {
    Map<String, dynamic>? body;
    if (e.body.isNotEmpty) {
      try {
        body = jsonDecode(e.body) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return ForgotPasswordFailure(
      statusCode: e.statusCode,
      body: body,
      error: e,
    );
  } catch (e) {
    return ForgotPasswordFailure(statusCode: -1, error: e);
  }
}

sealed class ResetPasswordResult {}

class ResetPasswordSuccess extends ResetPasswordResult {
  ResetPasswordSuccess({this.statusCode = 200, this.detail});
  final int statusCode;
  final String? detail;
}

class ResetPasswordFailure extends ResetPasswordResult {
  ResetPasswordFailure({required this.statusCode, this.body, this.error});
  final int statusCode;
  final Map<String, dynamic>? body;
  final Object? error;
}

/// POST /api/users/password-reset/confirm/ — valida el codi i desa la nova contrasenya.
Future<ResetPasswordResult> resetPassword(ResetPasswordRequest request) async {
  try {
    final response = await ApiClient.postJson(
      '/api/users/password-reset/confirm/',
      body: request.toJson(),
      expectedStatusCode: 200,
    );
    final dynamic decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : null;
    return ResetPasswordSuccess(
      statusCode: response.statusCode,
      detail: decoded?.toString(),
    );
  } on ApiException catch (e) {
    Map<String, dynamic>? body;
    if (e.body.isNotEmpty) {
      try {
        body = jsonDecode(e.body) as Map<String, dynamic>?;
      } catch (_) {}
    }
    return ResetPasswordFailure(statusCode: e.statusCode, body: body, error: e);
  } catch (e) {
    return ResetPasswordFailure(statusCode: -1, error: e);
  }
}
