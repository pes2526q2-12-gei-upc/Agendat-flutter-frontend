import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:flutter/material.dart';
import 'package:agendat/l10n/app_localizations.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _requestDeleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.confirmTitle),
          content: Text(l10n.deleteAccountConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      final result = await ProfileQuery.instance.deleteAccount();
      if (!mounted) return;

      switch (result) {
        case DeleteAccountSuccess():
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        case DeleteAccountUnauthorized():
          await showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(l10n.sessionExpiredTitle),
                content: Text(l10n.deleteAccountSessionExpiredBody),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.ok),
                  ),
                ],
              );
            },
          );
        case DeleteAccountFailure():
          await showDialog<void>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(l10n.deleteAccountErrorTitle),
                content: Text(l10n.deleteAccountFailureBody),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(l10n.ok),
                  ),
                ],
              );
            },
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.deleteAccountTitle)),
      body: Padding(
        padding: AppScreenSpacing.content,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.deleteAccountDescription),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _isDeleting ? null : _requestDeleteAccount,
              child: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.deleteAccountButton),
            ),
          ],
        ),
      ),
    );
  }
}
