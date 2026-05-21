import 'package:flutter/material.dart';

/// App-wide [SnackBar] helper: floating bar, close icon (Material 3), tap on
/// message text to dismiss. Uses the default [ScaffoldMessenger] queue unless
/// [replacePending] is true (clears current + pending, then shows this one).
abstract final class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    bool isError = true,
    Duration? duration,
    bool replacePending = false,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (replacePending) {
      messenger
        ..removeCurrentSnackBar()
        ..clearSnackBars();
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        duration: duration ?? const Duration(seconds: 4),
        backgroundColor: isError ? null : Colors.green.shade700,
        action: action,
        content: _TapToDismissMessage(message: message, messenger: messenger),
      ),
    );
  }
}

class _TapToDismissMessage extends StatelessWidget {
  const _TapToDismissMessage({required this.message, required this.messenger});

  final String message;
  final ScaffoldMessengerState messenger;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => messenger.hideCurrentSnackBar(),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(message),
            ),
          ),
        ),
      ],
    );
  }
}
