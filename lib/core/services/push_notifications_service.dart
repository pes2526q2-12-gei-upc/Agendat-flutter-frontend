import 'dart:async';
import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/services/token_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

bool get _supportsFirebaseMessaging {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_supportsFirebaseMessaging) return;

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('[PushNotifications] background init failed: $e');
  }
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  bool _firebaseReady = false;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_supportsFirebaseMessaging) {
      _initialized = true;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      _firebaseReady = true;
      _initialized = true;
      _messaging = messaging;
    } catch (e) {
      _firebaseReady = false;
      debugPrint('[PushNotifications] Firebase initialization failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging!.onTokenRefresh.listen(
      (token) async {
        final authToken = await TokenStorage.read();
        if (authToken == null || authToken.isEmpty) return;
        await _saveToken(token);
      },
      onError: (Object e) {
        debugPrint('[PushNotifications] token refresh failed: $e');
      },
    );
  }

  Future<void> requestPermissionAndRegisterDevice() async {
    await initialize();
    final messaging = _messaging;
    if (!_firebaseReady || messaging == null) return;

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushNotifications] notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[PushNotifications] Firebase returned no FCM token');
        return;
      }

      await _saveToken(token);
    } catch (e) {
      debugPrint('[PushNotifications] register device failed: $e');
    }
  }

  Future<void> unregisterDevice() async {
    final deviceId = await TokenStorage.readNotificationDeviceId();
    if (deviceId == null) return;

    try {
      await ApiClient.delete('/api/notifications/devices/$deviceId/');
      await TokenStorage.writeNotificationDeviceId(null);
    } catch (e) {
      debugPrint('[PushNotifications] unregister device failed: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final response = await ApiClient.postJson(
        '/api/notifications/devices/',
        body: {'token': token, 'platform': _platformName},
        expectedStatusCode: 201,
      );

      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>?
          : null;
      final id = decoded?['id'];
      if (id is int) {
        await TokenStorage.writeNotificationDeviceId(id);
      } else if (id is String) {
        await TokenStorage.writeNotificationDeviceId(int.tryParse(id));
      }
    } catch (e) {
      debugPrint('[PushNotifications] save token failed: $e');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }
}
