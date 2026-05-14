import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/avatars.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

/// Capçalera de l'AppBar amb avatar i nom de la persona amb qui es xateja.
class ConversationPartnerAppBarTitle extends StatelessWidget {
  const ConversationPartnerAppBarTitle({
    super.key,
    required this.partner,
    required this.onTap,
  });

  final UserSummary partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProfileCircleAvatar(
              radius: 18,
              profileImage: partner.profileImage,
              fallbackLabel: partner.displayName,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '@${partner.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
