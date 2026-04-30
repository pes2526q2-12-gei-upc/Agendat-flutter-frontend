import 'package:agendat/features/profile/data/profile_api.dart';

/// Actualitza la preferència de sincronització de calendari de l'usuari.
Future<UpdateProfileResult> updateCalendarSyncAllowed(
  int userId,
  bool enabled,
) {
  return updateUserProfile(userId, {'calendar_sync_allowed': enabled});
}
