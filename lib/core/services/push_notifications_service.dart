import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/services/notification_formatter.dart';
import 'package:agendat/core/services/notification_navigation.dart';
import 'package:agendat/core/services/notification_payload.dart';
import 'package:agendat/core/services/token_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

const String _logPrefix = '[PushNotifications]';
const String _androidChatChannelId = 'agendat_chat_messages';
const String _androidChatChannelName = 'Agenda\'t notifications';
const String _androidChatChannelDescription =
    'Notifications for Agenda\'t activity and reminders.';
const String _androidNotificationSmallIcon = 'ic_stat_agendat';
const ui.Color _androidNotificationColor = ui.Color(0xFFE53935);

final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool _localNotificationsInitialized = false;

bool get _supportsFirebaseMessaging {
  if (kIsWeb) return false;

  return switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS => true,
    _ => false,
  };
}

bool get _supportsAndroidLocalNotifications {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android;
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!_supportsFirebaseMessaging) return;

  try {
    WidgetsFlutterBinding.ensureInitialized();
    ui.DartPluginRegistrant.ensureInitialized();
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

  await _showAndroidStructuredNotification(message);
}

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();

  FirebaseMessaging? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _openedMessageSubscription;
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
    await messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
    await _initializeLocalNotifications();

    await _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
      onError: (Object e) {
        debugPrint('$_logPrefix foreground message listener failed: $e');
      },
    );

    await _openedMessageSubscription?.cancel();
    _openedMessageSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(openNotificationFromData(message.data)),
      onError: (Object e) {
        debugPrint('$_logPrefix opened message listener failed: $e');
      },
    );

    final initialMessage = await _messaging!.getInitialMessage();
    if (initialMessage != null) {
      unawaited(openNotificationFromData(initialMessage.data));
    }

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
    debugPrint('$_logPrefix foreground/opened message listeners registered');
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

Future<void> _handleForegroundMessage(RemoteMessage message) async {
  final dataKeys = _sortedDataKeys(message.data);
  debugPrint(
    '$_logPrefix foreground push received silently '
    '(hasNotification=${message.notification != null}, dataKeys=$dataKeys)',
  );
}

Future<void> _initializeLocalNotifications() async {
  if (!_supportsAndroidLocalNotifications || _localNotificationsInitialized) {
    return;
  }

  const initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings(_androidNotificationSmallIcon),
  );

  await _localNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      unawaited(openNotificationPayloadString(response.payload));
    },
  );
  const channel = AndroidNotificationChannel(
    _androidChatChannelId,
    _androidChatChannelName,
    description: _androidChatChannelDescription,
    importance: Importance.high,
  );

  await _localNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
  _localNotificationsInitialized = true;
}

Future<void> _showAndroidStructuredNotification(RemoteMessage message) async {
  if (!_supportsAndroidLocalNotifications) return;

  final dataKeys = _sortedDataKeys(message.data);
  debugPrint(
    '$_logPrefix Android push received '
    '(hasNotification=${message.notification != null}, dataKeys=$dataKeys)',
  );

  if (message.notification != null) {
    debugPrint(
      '$_logPrefix local chat notification skipped because this FCM payload '
      'contains a notification block. Android will show Firebase automatic UI; '
      'backend must send Android chat pushes as data-only to show the '
      'custom Agenda\'t notification icon locally.',
    );
    return;
  }

  final payload = NotificationPayload.fromData(message.data);
  if (payload == null) {
    debugPrint(
      '$_logPrefix local notification skipped because no structured or '
      'fallback display fields were found (dataKeys=$dataKeys)',
    );
    return;
  }

  try {
    await _initializeLocalNotifications();
    final notificationTitle = formatNotificationTitle(payload);
    final notificationBody = formatNotificationSubtitle(payload);
    if (notificationTitle.isEmpty && notificationBody.isEmpty) {
      debugPrint(
        '$_logPrefix local notification skipped because formatted display '
        'text is empty (dataKeys=$dataKeys)',
      );
      return;
    }
    final styleInformation = await _androidStyleFor(
      payload,
      title: notificationTitle,
      body: notificationBody,
    );

    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _androidChatChannelId,
        _androidChatChannelName,
        channelDescription: _androidChatChannelDescription,
        icon: _androidNotificationSmallIcon,
        category: _androidCategoryFor(payload),
        importance: Importance.high,
        priority: Priority.high,
        color: _androidNotificationColor,
        shortcutId: _conversationShortcutId(payload),
        ticker: notificationBody.isEmpty ? notificationTitle : notificationBody,
        styleInformation: styleInformation,
      ),
    );

    final notificationId = _notificationIdFor(message, payload);
    await _localNotificationsPlugin.show(
      id: notificationId,
      title: notificationTitle.isEmpty ? null : notificationTitle,
      body: notificationBody.isEmpty ? null : notificationBody,
      notificationDetails: notificationDetails,
      payload: jsonEncode(payload.toNotificationPayload()),
    );
    debugPrint(
      '$_logPrefix local notification shown '
      '(id=$notificationId)',
    );
  } catch (e) {
    debugPrint('$_logPrefix local notification failed: $e');
  }
}

Future<StyleInformation?> _androidStyleFor(
  NotificationPayload payload, {
  required String title,
  required String body,
}) async {
  final imageUrl = payload.preview?.imageUrl?.trim();
  if (imageUrl != null && imageUrl.isNotEmpty) {
    final imageBytes = await _downloadNotificationImage(imageUrl);
    if (imageBytes != null) {
      return BigPictureStyleInformation(
        ByteArrayAndroidBitmap(imageBytes),
        contentTitle: title.isEmpty ? null : title,
        summaryText: body.isEmpty ? null : body,
      );
    }
  }

  return body.isEmpty ? null : BigTextStyleInformation(body);
}

Future<Uint8List?> _downloadNotificationImage(String imageUrl) async {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null || !uri.hasScheme) return null;

  try {
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final bytes = response.bodyBytes;
    const maxNotificationImageBytes = 5 * 1024 * 1024;
    if (bytes.isEmpty || bytes.length > maxNotificationImageBytes) return null;
    return bytes;
  } catch (e) {
    debugPrint('$_logPrefix notification image download failed: $e');
    return null;
  }
}

List<String> _sortedDataKeys(Map<String, dynamic> data) {
  final keys = data.keys.map((key) => key.toString()).toList()..sort();
  return keys;
}

int _notificationIdFor(RemoteMessage message, NotificationPayload payload) {
  final raw = payload.id ??
      _routeParam(payload, 'message_id') ??
      _routeParam(payload, 'invitation_id') ??
      _routeParam(payload, 'review_id') ??
      _routeParam(payload, 'session_id') ??
      message.messageId ??
      message.sentTime?.toString();
  if (raw == null || raw.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
  }
  return raw.hashCode & 0x7fffffff;
}

String? _conversationShortcutId(NotificationPayload payload) {
  if (payload.action?.key != 'chat.message') return null;
  final chatId = _routeParam(payload, 'chat_id') ?? payload.target?.id;
  if (chatId == null) return null;

  final normalized = chatId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return normalized.isEmpty ? null : 'chat_$normalized';
}

AndroidNotificationCategory _androidCategoryFor(NotificationPayload payload) {
  return switch (payload.action?.key) {
    'chat.message' => AndroidNotificationCategory.message,
    'event.reminder' => AndroidNotificationCategory.reminder,
    'friend_request.sent' || 'friend_request.accepted' =>
      AndroidNotificationCategory.social,
    _ => AndroidNotificationCategory.status,
  };
}

String? _routeParam(NotificationPayload payload, String key) {
  final params = payload.target?.route?.params;
  final value = params?[key]?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return value;
}
