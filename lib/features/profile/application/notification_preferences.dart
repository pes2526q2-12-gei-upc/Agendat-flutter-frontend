import 'package:agendat/core/models/user_profile.dart';

enum NotificationPreferenceChannel {
  eventReminders,
  eventUpdates,
  socialAlerts,
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.notificationsAllowed,
    required this.eventRemindersAllowed,
    required this.eventUpdatesAllowed,
    required this.socialAlertsAllowed,
  });

  factory NotificationPreferences.fromProfile(UserProfile profile) {
    return NotificationPreferences(
      notificationsAllowed: profile.notificationsAllowed,
      eventRemindersAllowed: profile.eventRemindersAllowed,
      eventUpdatesAllowed: profile.eventUpdatesAllowed,
      socialAlertsAllowed: profile.socialAlertsAllowed,
    );
  }

  final bool notificationsAllowed;
  final bool eventRemindersAllowed;
  final bool eventUpdatesAllowed;
  final bool socialAlertsAllowed;

  NotificationPreferences withMasterSwitch(bool enabled) {
    return NotificationPreferences(
      notificationsAllowed: enabled,
      eventRemindersAllowed: enabled,
      eventUpdatesAllowed: enabled,
      socialAlertsAllowed: enabled,
    );
  }

  NotificationPreferences withChannel(
    NotificationPreferenceChannel channel,
    bool enabled,
  ) {
    final eventReminders =
        channel == NotificationPreferenceChannel.eventReminders
        ? enabled
        : eventRemindersAllowed;
    final eventUpdates = channel == NotificationPreferenceChannel.eventUpdates
        ? enabled
        : eventUpdatesAllowed;
    final socialAlerts = channel == NotificationPreferenceChannel.socialAlerts
        ? enabled
        : socialAlertsAllowed;

    return NotificationPreferences(
      notificationsAllowed: eventReminders || eventUpdates || socialAlerts,
      eventRemindersAllowed: eventReminders,
      eventUpdatesAllowed: eventUpdates,
      socialAlertsAllowed: socialAlerts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications_allowed': notificationsAllowed,
      'event_reminders_allowed': eventRemindersAllowed,
      'event_updates_allowed': eventUpdatesAllowed,
      'social_alerts_allowed': socialAlertsAllowed,
    };
  }
}
