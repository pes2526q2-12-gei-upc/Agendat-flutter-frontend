import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/services/notification_formatter.dart';
import 'package:agendat/core/services/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('notification formatter', () {
    test('formats actor primary text from localized action key', () {
      const notification = NotificationPayload(
        actor: NotificationActor(displayName: 'Maria'),
        action: NotificationAction(key: 'friend_request.sent'),
        title: 'Backend fallback',
      );

      expect(
        formatNotificationTitle(notification, languageCode: 'EN'),
        'Maria sent you a friend request',
      );
    });

    test('formats target-only primary text for event reminders', () {
      const notification = NotificationPayload(
        action: NotificationAction(key: 'event.reminder'),
        target: NotificationTarget(name: 'Concert de Primavera'),
      );

      expect(
        formatNotificationTitle(notification, languageCode: 'EN'),
        'Concert de Primavera starts soon',
      );
    });

    test('uses preview text before target name and fallback body', () {
      const notification = NotificationPayload(
        body: 'Fallback body',
        target: NotificationTarget(name: 'Concert de Primavera'),
        preview: NotificationPreview(text: 'Hola'),
      );

      expect(formatNotificationSubtitle(notification), 'Hola');
    });

    test('uses fallback title and body when action key is unknown', () {
      const notification = NotificationPayload(
        title: 'Backend title',
        body: 'Backend body',
        action: NotificationAction(key: 'unknown.action', label: 'Raw label'),
      );

      expect(formatNotificationTitle(notification), 'Backend title');
      expect(formatNotificationSubtitle(notification), 'Backend body');
    });

    test('falls back to action label when title is missing and key is unknown', () {
      const notification = NotificationPayload(
        action: NotificationAction(key: 'unknown.action', label: 'Raw label'),
      );

      expect(formatNotificationTitle(notification), 'Raw label');
    });

    test('localizes known action labels from AppLanguage', () {
      AppLanguage.setCode('ES');
      expect(
        localizedNotificationActionLabel('chat.message'),
        'te ha enviado un mensaje',
      );

      AppLanguage.setCode('CA');
      expect(
        localizedNotificationActionLabel('event.reminder'),
        'comenca aviat',
      );

      AppLanguage.setCode('EN');
      expect(
        localizedNotificationActionLabel('review.liked'),
        'liked your review',
      );
    });
  });
}
