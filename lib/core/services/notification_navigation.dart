import 'dart:convert';

import 'package:agendat/core/navigation/app_navigator.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/services/notification_payload.dart';
import 'package:agendat/core/services/notification_route_destination.dart';
import 'package:agendat/features/chat/presentation/screens/friend_conversation_screen.dart';
import 'package:agendat/features/events/presentation/screens/event_view_screen.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/presentation/screens/social_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> openNotificationFromData(Map<String, dynamic> data) async {
  final notification = NotificationPayload.fromData(data);
  if (notification == null) {
    _log('tap ignored because payload could not be parsed');
    return;
  }
  await openNotification(notification);
}

Future<void> openNotificationPayloadString(String? payload) async {
  if (payload == null || payload.trim().isEmpty) {
    _log('tap ignored because notification payload is empty');
    return;
  }

  try {
    final decoded = jsonDecode(payload);
    if (decoded is Map<String, dynamic>) {
      await openNotificationFromData(decoded);
      return;
    }
    if (decoded is Map) {
      await openNotificationFromData(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
      return;
    }
  } catch (e) {
    _log('tap ignored because notification payload JSON is invalid: $e');
    return;
  }

  _log('tap ignored because notification payload is not an object');
}

Future<void> openNotification(NotificationPayload notification) async {
  final destination = notificationDestinationFromPayload(notification);
  if (destination == null) {
    _log('tap ignored because route data is missing or unsupported');
    return;
  }

  final navigator = appNavigatorKey.currentState;
  if (navigator == null) {
    _log('tap ignored because navigator is not ready');
    return;
  }

  switch (destination.type) {
    case NotificationDestinationType.chatDetail:
      final chatId = destination.chatId;
      if (chatId == null) return;
      try {
        final chat = await ChatsQuery.instance.getChat(
          chatId,
          forceRefresh: true,
        );
        navigator.push<void>(
          MaterialPageRoute<void>(
            builder: (_) => FriendConversationScreen(chat: chat),
          ),
        );
      } catch (e) {
        _log('chat notification route failed for chat $chatId: $e');
      }
    case NotificationDestinationType.friendRequests:
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const SocialScreen()),
      );
    case NotificationDestinationType.userProfile:
      final userId = destination.userId;
      if (userId == null) return;
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => ProfileScreen(userId: userId)),
      );
    case NotificationDestinationType.eventInvitationDetail:
    case NotificationDestinationType.eventReviewDetail:
    case NotificationDestinationType.eventSessionDetail:
      final eventCode = destination.eventCode;
      if (eventCode == null || eventCode.isEmpty) return;
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => EventScreen(eventCode: eventCode),
        ),
      );
  }
}

void _log(String message) {
  if (kDebugMode) debugPrint('[PushNotifications] $message');
}
