import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/l10n/app_localizations.dart';

class ProfileFriendshipSection extends StatelessWidget {
  const ProfileFriendshipSection({
    super.key,
    required this.currentUserId,
    required this.viewedUserId,
    required this.status,
    required this.isFriendshipBusy,
    required this.isBlockBusy,
    required this.onSendFriendRequest,
    required this.onCancelFriendRequest,
    required this.onAcceptFriendRequest,
    required this.onRejectFriendRequest,
    required this.onUnfriend,
    required this.onUnblock,
  });

  final int? currentUserId;

  /// [ProfileScreen.userId] quan es visita un altre perfil; null al perfil propi.
  final int? viewedUserId;
  final FriendshipStatus status;
  final bool isFriendshipBusy;
  final bool isBlockBusy;
  final VoidCallback onSendFriendRequest;
  final VoidCallback onCancelFriendRequest;
  final VoidCallback onAcceptFriendRequest;
  final VoidCallback onRejectFriendRequest;
  final VoidCallback onUnfriend;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null ||
        viewedUserId == null ||
        viewedUserId == currentUserId) {
      return const SizedBox.shrink();
    }

    final busy = isFriendshipBusy;

    switch (status) {
      case FriendshipStatus.none:
        return _FriendshipPrimaryButton(
          onPressed: busy ? null : onSendFriendRequest,
          icon: Icons.person_add_alt_1,
          label: AppLocalizations.of(context).sendFriendRequest,
          busy: busy,
        );
      case FriendshipStatus.requestSent:
        return _FriendshipOutlinedButton(
          onPressed: busy ? null : onCancelFriendRequest,
          icon: Icons.hourglass_top,
          label: AppLocalizations.of(context).friendRequestSentCancel,
          busy: busy,
        );
      case FriendshipStatus.requestReceived:
        return Row(
          children: [
            Expanded(
              child: _FriendshipPrimaryButton(
                onPressed: busy ? null : onAcceptFriendRequest,
                icon: Icons.check,
                label: AppLocalizations.of(context).accept,
                busy: busy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FriendshipOutlinedButton(
                onPressed: busy ? null : onRejectFriendRequest,
                icon: Icons.close,
                label: AppLocalizations.of(context).reject,
                busy: false,
              ),
            ),
          ],
        );
      case FriendshipStatus.friends:
        return _FriendshipOutlinedButton(
          onPressed: busy ? null : onUnfriend,
          icon: Icons.person_remove_outlined,
          label: AppLocalizations.of(context).removeFriend,
          busy: busy,
        );
      case FriendshipStatus.blockedByMe:
        return _FriendshipOutlinedButton(
          onPressed: isBlockBusy ? null : onUnblock,
          icon: Icons.lock_open,
          label: AppLocalizations.of(context).unblock,
          busy: isBlockBusy,
        );
      case FriendshipStatus.blockedMe:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.block, size: 18, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).blockedYou,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _FriendshipPrimaryButton extends StatelessWidget {
  const _FriendshipPrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.busy,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: EventTextUtils.kPrimaryRed,
          foregroundColor: Colors.white,
          disabledBackgroundColor: EventTextUtils.kPrimaryRed.withValues(
            alpha: 0.6,
          ),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FriendshipOutlinedButton extends StatelessWidget {
  const _FriendshipOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.busy,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: EventTextUtils.kPrimaryRed,
          side: const BorderSide(color: EventTextUtils.kPrimaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
