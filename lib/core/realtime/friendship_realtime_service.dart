import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/realtime/friendship_realtime_event.dart';
import 'package:agendat/core/state/auth_session.dart';

class FriendshipRealtimeService {
  static final FriendshipRealtimeService instance =
      FriendshipRealtimeService._();
  FriendshipRealtimeService._();

  final StreamController<FriendshipRealtimeEvent> _events =
      StreamController<FriendshipRealtimeEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _token;
  bool _closedByClient = true;

  Stream<FriendshipRealtimeEvent> get events => _events.stream;

  bool get isConnected => _channel != null;

  void connect({String? token}) {
    final normalizedToken = (token ?? currentAuthToken)?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      disconnect();
      return;
    }

    if (_channel != null && _token == normalizedToken) return;

    disconnect();
    _closedByClient = false;
    _token = normalizedToken;
    _open(normalizedToken);
  }

  void disconnect() {
    _closedByClient = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    _channel?.sink.close();
    _channel = null;
    _token = null;
  }

  @visibleForTesting
  static Uri socketUriForToken(String token, {String? baseUrl}) {
    final base = Uri.parse(baseUrl ?? ApiClient.baseUrl);
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: scheme,
      path: '/ws/friends/',
      queryParameters: <String, String>{'token': token},
    );
  }

  void _open(String token) {
    final uri = socketUriForToken(token);
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleRawEvent,
        onError: (Object error, StackTrace stackTrace) {
          if (kDebugMode) {
            debugPrint('[friendship_realtime] socket error: $error');
          }
          _scheduleReconnect(token);
        },
        onDone: () => _scheduleReconnect(token),
        cancelOnError: true,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[friendship_realtime] connect failed: $error');
      }
      _scheduleReconnect(token);
    }
  }

  void _handleRawEvent(dynamic raw) {
    if (raw is! String) return;

    final dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    final event = FriendshipRealtimeEvent.tryParse(decoded);
    if (event == null) return;

    _events.add(event);
  }

  void _scheduleReconnect(String token) {
    _subscription = null;
    _channel = null;
    if (_closedByClient || _token != token || _reconnectTimer != null) return;

    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      _reconnectTimer = null;
      if (!_closedByClient && _token == token) {
        _open(token);
      }
    });
  }
}
