import 'package:flutter/material.dart';

import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/avatars.dart';

class InviteFriendTile extends StatelessWidget {
  const InviteFriendTile({
    required this.friend,
    required this.selected,
    required this.disabled,
    required this.existingStatus,
    required this.onTap,
  });

  final UserSummary friend;
  final bool selected;
  final bool disabled;
  final EventInvitationStatus? existingStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const selectionColor = AppThemeTokens.brandPrimary;

    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? selectionColor : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                ProfileCircleAvatar(
                  radius: 22,
                  profileImage: friend.profileImage,
                  fallbackLabel: friend.displayName,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${friend.username}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (existingStatus != null) ...[
                  InviteFriendStatusBadge(status: existingStatus!),
                ] else ...[
                  Checkbox(
                    value: selected,
                    onChanged: disabled ? null : (_) => onTap(),
                    activeColor: selectionColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InviteFriendStatusBadge extends StatelessWidget {
  const InviteFriendStatusBadge({required this.status});

  final EventInvitationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EventInvitationStatus.pending => ('Pendent', Colors.orange),
      EventInvitationStatus.accepted => ('Acceptada', Colors.green),
      EventInvitationStatus.denied => ('Denegada', Colors.redAccent),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
