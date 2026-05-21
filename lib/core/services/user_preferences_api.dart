import 'package:agendat/core/api/profile_api.dart';

/// Actualitza la preferència de sincronització de calendari de l'usuari.
Future<UpdateProfileResult> updateCalendarSyncAllowed(
  int userId,
  bool enabled,
) {
  return updateUserProfile(userId, {'calendar_sync_allowed': enabled});
}

/// Actualitza l'idioma seleccionat de l'usuari al backend.
Future<UpdateProfileResult> updateSelectedLanguage(
  int userId,
  String languageCode,
) {
  return updateUserProfile(userId, {'selected_language': languageCode});
}
