import 'package:flutter/material.dart';

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/features/chat/presentation/screens/friend_conversation_screen.dart';
import 'package:agendat/features/events/presentation/screens/event_view_screen.dart';
import 'package:agendat/features/profile/presentation/screens/blocked_users_screen.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';

/// Central entry points for cross-feature navigation.
abstract final class FeatureNavigation {
  /// Obre el perfil d'un usuari (`userId`) o el propi (`userId == null`).
  static Future<T?> openUserProfile<T extends Object?>(
    BuildContext context, {
    int? userId,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => ProfileScreen(userId: userId)),
    );
  }

  /// Obre el detall d'un esdeveniment per codi.
  static Future<T?> openEventDetail<T extends Object?>(
    BuildContext context, {
    required String eventCode,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => EventScreen(eventCode: eventCode)),
    );
  }

  /// Obre una conversa de xat amb un amic.
  static Future<void> openFriendConversation(
    BuildContext context, {
    required Chat chat,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FriendConversationScreen(chat: chat),
      ),
    );
  }

  /// Obre la pantalla de usuaris bloquejats.
  static Future<T?> openBlockedUsers<T extends Object?>(BuildContext context) {
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => const BlockedUsersScreen()));
  }
}
