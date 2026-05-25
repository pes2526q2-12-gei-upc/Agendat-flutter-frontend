import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('push notification device registration body', () {
    test('includes selected language with token and platform', () {
      final body = buildNotificationDeviceRegistrationBody(
        token: 'fcm-token',
        platform: 'android',
        languageCode: 'ES',
      );

      expect(body, {
        'token': 'fcm-token',
        'platform': 'android',
        'selected_language': 'ES',
      });
    });

    test('normalizes unsupported selected language to default', () {
      final body = buildNotificationDeviceRegistrationBody(
        token: 'fcm-token',
        platform: 'ios',
        languageCode: 'fr',
      );

      expect(body['selected_language'], 'CA');
    });
  });
}
