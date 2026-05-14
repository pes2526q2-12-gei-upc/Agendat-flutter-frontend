import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/utils/profile_image_url.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

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
            child: BlockedUserAvatar(profileImage: user.profileImage),
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
  const BlockedUserAvatar({super.key, required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    const size = radius * 2;
    final imageUrl = resolveProfileImageUrl(profileImage);

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 26, color: Colors.grey.shade500),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Icon(Icons.person, size: 26, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
