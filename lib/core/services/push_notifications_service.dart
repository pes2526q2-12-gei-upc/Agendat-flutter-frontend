import 'dart:async';
import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/services/token_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

const String _logPrefix = '[PushNotifications]';

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
  } on FirebaseException catch (e) {
    debugPrint(
      '$_logPrefix background Firebase init failed '
      '(${e.code}): ${e.message ?? e}',
    );
  } catch (e) {
    debugPrint('$_logPrefix background Firebase init failed: $e');
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
      debugPrint(
        '$_logPrefix Firebase Messaging is not supported on '
        '${defaultTargetPlatform.name}',
      );
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
      debugPrint(
        '$_logPrefix Firebase initialized on ${defaultTargetPlatform.name}',
      );
    } on FirebaseException catch (e) {
      _firebaseReady = false;
      debugPrint(
        '$_logPrefix Firebase initialization failed '
        '(${e.code}): ${e.message ?? e}. '
        'On Android, verify android/app/google-services.json exists and '
        'matches applicationId com.example.agendat.',
      );
      return;
    } catch (e) {
      _firebaseReady = false;
      debugPrint('$_logPrefix Firebase initialization failed: $e');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging!.onTokenRefresh.listen(
      (token) async {
        debugPrint('$_logPrefix FCM token refreshed (${_tokenSummary(token)})');
        _debugLogFullFcmToken(token);
        final authToken = await TokenStorage.read();
        if (authToken == null || authToken.isEmpty) {
          debugPrint(
            '$_logPrefix token refresh ignored because no auth token exists',
          );
          return;
        }
        await _saveToken(token);
      },
      onError: (Object e) {
        debugPrint('$_logPrefix token refresh failed: $e');
      },
    );
    debugPrint('$_logPrefix token refresh listener registered');
  }

  Future<void> requestPermissionAndRegisterDevice() async {
    await initialize();
    final messaging = _messaging;
    if (!_firebaseReady || messaging == null) {
      debugPrint(
        '$_logPrefix device registration skipped because Firebase is not ready',
      );
      return;
    }

    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        '$_logPrefix notification permission status: '
        '${settings.authorizationStatus.name}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('$_logPrefix notification permission denied');
        return;
      }

      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('$_logPrefix Firebase returned no FCM token');
        return;
      }

      debugPrint('$_logPrefix FCM token obtained (${_tokenSummary(token)})');
      _debugLogFullFcmToken(token);
      await _saveToken(token);
    } catch (e) {
      debugPrint('$_logPrefix register device failed: $e');
    }
  }

  Future<void> unregisterDevice() async {
    final deviceId = await TokenStorage.readNotificationDeviceId();
    if (deviceId == null) {
      debugPrint(
        '$_logPrefix unregister skipped because no device id is saved',
      );
      return;
    }

    try {
      await ApiClient.delete('/api/notifications/devices/$deviceId/');
      await TokenStorage.writeNotificationDeviceId(null);
      debugPrint('$_logPrefix device $deviceId unregistered');
    } on ApiException catch (e) {
      debugPrint(
        '$_logPrefix unregister device failed '
        '(HTTP ${e.statusCode}) for ${e.uri}: ${e.body}',
      );
    } catch (e) {
      debugPrint('$_logPrefix unregister device failed: $e');
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      final response = await ApiClient.postJson(
        '/api/notifications/devices/',
        body: {'token': token, 'platform': _platformName},
        expectedStatusCode: 201,
      );

      final decoded = _decodeJsonMap(response.body);
      final id = decoded?['id'];
      if (id is int) {
        await TokenStorage.writeNotificationDeviceId(id);
        debugPrint('$_logPrefix device token registered as backend device $id');
      } else if (id is String) {
        final parsedId = int.tryParse(id);
        await TokenStorage.writeNotificationDeviceId(parsedId);
        debugPrint(
          '$_logPrefix device token registered as backend device '
          '${parsedId ?? id}',
        );
      } else {
        debugPrint(
          '$_logPrefix device token registered, but response had no id '
          '(HTTP ${response.statusCode})',
        );
      }
    } on ApiException catch (e) {
      debugPrint(
        '$_logPrefix save token failed '
        '(HTTP ${e.statusCode}) for ${e.uri}: ${e.body}',
      );
    } catch (e) {
      debugPrint('$_logPrefix save token failed: $e');
    }
  }

  Map<String, dynamic>? _decodeJsonMap(String body) {
    if (body.isEmpty) return null;
    final decoded = jsonDecode(body);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  String _tokenSummary(String token) => 'length ${token.length}';

  void _debugLogFullFcmToken(String token) {
    if (!kDebugMode) return;
    debugPrint('$_logPrefix DEBUG FCM token for Swagger/curl: $token');
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
