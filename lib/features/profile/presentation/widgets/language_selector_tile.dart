import 'package:flutter/material.dart';

import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/l10n/app_localizations.dart';

class LanguageSelectorTile extends StatefulWidget {
  const LanguageSelectorTile({
    super.key,
    required this.userId,
    required this.unauthenticatedMessage,
    required this.onShowMessage,
  });

  static const String unauthenticatedMessageDefault = '';

  final int userId;
  final String unauthenticatedMessage;
  final void Function(String message) onShowMessage;

  @override
  State<LanguageSelectorTile> createState() => _LanguageSelectorTileState();
}

class _LanguageSelectorTileState extends State<LanguageSelectorTile> {
  static const List<String> _orderedCodes = ['CA', 'EN', 'ES'];
  bool _isSavingLanguage = false;

  Future<void> _revertLanguage(String previous) async {
    AppLanguage.setCode(previous);
    await AppLanguage.persist();
    if (mounted) setState(() {});
  }

  Future<void> _onLanguageSelected(String? code) async {
    if (_isSavingLanguage || code == null || code == AppLanguage.code) return;

    if (currentLoggedInUser == null || currentAuthToken == null) {
      widget.onShowMessage(widget.unauthenticatedMessage);
      return;
    }

    final previous = AppLanguage.code;
    AppLanguage.setCode(code);
    if (AppLanguage.code == previous) return;

    setState(() => _isSavingLanguage = true);

    try {
      await AppLanguage.persist();
      if (mounted) setState(() {});

      final result = await updateUserProfile(widget.userId, {
        'selected_language': code,
      });

      if (!mounted) return;

      switch (result) {
        case UpdateProfileSuccess(:final profile):
          await setCurrentLoggedInUser({
            ...currentLoggedInUser ?? <String, dynamic>{},
            ...profile.toJson(),
            'id': profile.id,
            'selected_language': code,
          });
          EventsQuery.instance.refreshTranslatedContent();
        case UpdateProfileFailure(:final statusCode):
          await _revertLanguage(previous);
          if (statusCode == 401 || statusCode == 403) {
            widget.onShowMessage(widget.unauthenticatedMessage);
          } else if (statusCode == -1) {
            widget.onShowMessage(
              'Error de connexió. Comprova la teva connexió.',
            );
          } else {
            widget.onShowMessage('No s\'ha pogut desar l\'idioma.');
          }
        case UpdateProfileValidationError():
          await _revertLanguage(previous);
          widget.onShowMessage('No s\'ha pogut desar l\'idioma.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingLanguage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.listenable,
      builder: (context, selectedCode, _) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: EventTextUtils.kPrimaryRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.language,
                color: EventTextUtils.kPrimaryRed,
              ),
            ),
            title: Text(
              l10n.language,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(l10n.chooseAppLanguage),
            trailing: DropdownButton<String>(
              value: selectedCode,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [
                for (final code in _orderedCodes)
                  DropdownMenuItem<String>(
                    value: code,
                    child: Text(AppLanguage.displayNamesByCode[code]!),
                  ),
              ],
              onChanged: _isSavingLanguage ? null : _onLanguageSelected,
            ),
          ),
        );
      },
    );
  }
}
