import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/core/widgets/avatars.dart';

class BlockedUserTile extends StatelessWidget {
  const BlockedUserTile({
    super.key,
    required this.user,
    required this.onOpenProfile,
  });

  final UserSummary user;
  final ValueChanged<UserSummary> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.username.trim().isNotEmpty ? user.username.trim() : 'Usuari');
    final username = user.username.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onOpenProfile(user),
            child: BlockedUserAvatar(user: user),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => onOpenProfile(user),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BlockedUserAvatar extends StatelessWidget {
  const BlockedUserAvatar({super.key, required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    return ProfileCircleAvatar(
      radius: 24,
      profileImage: user.profileImage,
      fallbackLabel: user.displayName,
      fallback: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 26, color: Colors.grey.shade500),
      ),
      userId: user.id,
      reputation: user.reputation,
      showLevelRing: true,
    );
  }
}
