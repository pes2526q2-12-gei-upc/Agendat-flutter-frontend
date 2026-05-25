import 'package:agendat/features/profile/application/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    test('main switch off disables all notification flags', () {
      const preferences = NotificationPreferences(
        notificationsAllowed: true,
        eventRemindersAllowed: true,
        eventUpdatesAllowed: true,
        socialAlertsAllowed: true,
      );

      final updated = preferences.withMasterSwitch(false);

      expect(updated.notificationsAllowed, isFalse);
      expect(updated.eventRemindersAllowed, isFalse);
      expect(updated.eventUpdatesAllowed, isFalse);
      expect(updated.socialAlertsAllowed, isFalse);
    });

    test('main switch on enables all notification flags', () {
      const preferences = NotificationPreferences(
        notificationsAllowed: false,
        eventRemindersAllowed: false,
        eventUpdatesAllowed: false,
        socialAlertsAllowed: false,
      );

      final updated = preferences.withMasterSwitch(true);

      expect(updated.notificationsAllowed, isTrue);
      expect(updated.eventRemindersAllowed, isTrue);
      expect(updated.eventUpdatesAllowed, isTrue);
      expect(updated.socialAlertsAllowed, isTrue);
    });

    test('turning one sub-alert on enables the master switch', () {
      const preferences = NotificationPreferences(
        notificationsAllowed: false,
        eventRemindersAllowed: false,
        eventUpdatesAllowed: false,
        socialAlertsAllowed: false,
      );

      final updated = preferences.withChannel(
        NotificationPreferenceChannel.socialAlerts,
        true,
      );

      expect(updated.notificationsAllowed, isTrue);
      expect(updated.eventRemindersAllowed, isFalse);
      expect(updated.eventUpdatesAllowed, isFalse);
      expect(updated.socialAlertsAllowed, isTrue);
    });

    test('turning the last sub-alert off disables the master switch', () {
      const preferences = NotificationPreferences(
        notificationsAllowed: true,
        eventRemindersAllowed: false,
        eventUpdatesAllowed: true,
        socialAlertsAllowed: false,
      );

      final updated = preferences.withChannel(
        NotificationPreferenceChannel.eventUpdates,
        false,
      );

      expect(updated.notificationsAllowed, isFalse);
      expect(updated.eventRemindersAllowed, isFalse);
      expect(updated.eventUpdatesAllowed, isFalse);
      expect(updated.socialAlertsAllowed, isFalse);
    });

    test('failure rollback can restore the previous snapshot', () {
      const previous = NotificationPreferences(
        notificationsAllowed: true,
        eventRemindersAllowed: true,
        eventUpdatesAllowed: false,
        socialAlertsAllowed: false,
      );

      final requested = previous.withMasterSwitch(false);
      final rolledBack = previous;

      expect(requested.notificationsAllowed, isFalse);
      expect(rolledBack.notificationsAllowed, isTrue);
      expect(rolledBack.eventRemindersAllowed, isTrue);
      expect(rolledBack.eventUpdatesAllowed, isFalse);
      expect(rolledBack.socialAlertsAllowed, isFalse);
    });
  });
}
