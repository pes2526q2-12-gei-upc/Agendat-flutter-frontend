import 'package:flutter/material.dart';

import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/l10n/app_localizations.dart';

/// Card with master notifications switch and expandable sub-alerts.
class NotificationAlertsBlock extends StatelessWidget {
  const NotificationAlertsBlock({
    super.key,
    required this.notificationsAllowed,
    required this.enabled,
    required this.onToggleNotifications,
    required this.child,
  });

  final bool notificationsAllowed;
  final bool enabled;
  final ValueChanged<bool> onToggleNotifications;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Column(
        children: [
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return SwitchListTile.adaptive(
                title: Text(
                  l10n.notificationPreferencesTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(l10n.notificationPreferencesIntro),
                value: notificationsAllowed,
                onChanged: enabled ? onToggleNotifications : null,
                activeThumbColor: EventTextUtils.kPrimaryRed,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              );
            },
          ),

          if (notificationsAllowed)
            Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: child,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class SubalertSwitchTile extends StatelessWidget {
  const SubalertSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(subtitle),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: EventTextUtils.kPrimaryRed,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
