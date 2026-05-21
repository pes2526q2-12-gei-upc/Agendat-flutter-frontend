import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/realtime/chat_realtime_service.dart';
import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/realtime/friendship_realtime_service.dart';
import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/core/services/token_storage.dart';
import 'package:agendat/core/state/auth_session.dart';
import 'package:agendat/core/state/pending_friend_requests_notifier.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';

export 'package:agendat/core/state/auth_session.dart';

Future<void> setCurrentLoggedInUser(Map<String, dynamic>? userJson) async {
  final normalizedUser = _normalizeLoggedInUser(userJson);
  currentLoggedInUser = normalizedUser;
  await TokenStorage.writeUser(normalizedUser);

  final selectedLanguage = normalizedUser?['selected_language'];
  if (selectedLanguage != null) {
    await AppLanguage.syncFromBackend(selectedLanguage.toString());
  }
}

/// Sincronitza l'idioma local amb el perfil de l'usuari autenticat al backend.
Future<void> syncAuthenticatedUserLanguageFromBackend(int userId) async {
  final result = await fetchUserProfile(userId);
  if (result is! ProfileSuccess) return;

  await setCurrentLoggedInUser({
    ...currentLoggedInUser ?? <String, dynamic>{},
    ...result.profile.toJson(),
    'id': result.profile.id,
  });
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
  ChatRealtimeService.instance.connect(token: token);
  FriendshipRealtimeService.instance.connect(token: token);
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
  ChatRealtimeService.instance.disconnect();
  FriendshipRealtimeService.instance.disconnect();
  unreadChatConversationsNotifier.value = 0;
  pendingFriendRequestsNotifier.value = 0;
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
  ChatRealtimeService.instance.connect(token: currentAuthToken);
  FriendshipRealtimeService.instance.connect(token: currentAuthToken);

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
