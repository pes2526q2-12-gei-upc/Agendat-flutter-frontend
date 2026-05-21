import 'package:flutter/material.dart';

import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';

/// Whether the user has a non-empty auth token (and optionally a logged-in id).
bool isAuthenticated({bool requireUserId = false}) {
  final hasToken =
      currentAuthToken != null && currentAuthToken!.trim().isNotEmpty;
  if (!requireUserId) return hasToken;
  return hasToken && currentLoggedInUser?['id'] is int;
}

/// If not authenticated, shows [message] in a snackbar and navigates to login.
/// Returns `true` when the user is authenticated.
bool guardAuthenticated(
  BuildContext context, {
  required String message,
  bool requireUserId = false,
}) {
  if (isAuthenticated(requireUserId: requireUserId) || !context.mounted) {
    return isAuthenticated(requireUserId: requireUserId);
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (route) => false,
  );
  return false;
}
