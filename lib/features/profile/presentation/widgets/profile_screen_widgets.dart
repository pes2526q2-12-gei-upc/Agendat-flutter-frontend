import 'package:flutter/material.dart';

import 'package:agendat/core/models/session.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:agendat/core/query/sessions_query.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';

class ProfileLoadErrorBody extends StatelessWidget {
  const ProfileLoadErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: AppScreenSpacing.section),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: AppScreenSpacing.section),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({
    required this.isLoggingOut,
    required this.onPressed,
  });

  final bool isLoggingOut;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: isLoggingOut
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.logout_outlined),
        style: OutlinedButton.styleFrom(
          foregroundColor: EventTextUtils.kPrimaryRed,
          side: const BorderSide(color: EventTextUtils.kPrimaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        label: Text(
          AppLocalizations.of(context).logout,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class ProfileAttendedTabLabel extends StatelessWidget {
  const ProfileAttendedTabLabel({required this.sessionsQuery});

  final SessionsQuery sessionsQuery;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Session>>(
      future: sessionsQuery.getSessions(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).showAttended),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Accions disponibles al menú contextual del perfil d'un altre usuari.
enum ProfileMenuAction { toggleBlock }
