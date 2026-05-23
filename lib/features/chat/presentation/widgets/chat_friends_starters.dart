import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/avatars.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/l10n/app_localizations.dart';

/// Llista d'amics per iniciar un xat quan encara no hi ha converses.
class ChatFriendsStarters extends StatelessWidget {
  const ChatFriendsStarters({
    super.key,
    required this.loading,
    required this.friends,
    required this.onFriendTap,
  });

  final bool loading;
  final List<UserSummary> friends;
  final ValueChanged<UserSummary> onFriendTap;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Center(
          child: Text(
            AppLocalizations.of(context).noFriendsAvailableToStartChat,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sorted = [...friends]
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).startChatWithFriendsTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 10),
        ...sorted.map(
          (friend) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: ProfileCircleAvatar(
                radius: 22,
                profileImage: friend.profileImage,
                fallbackLabel: friend.displayName,
              ),
              title: Text(
                friend.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '@${friend.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chat_outlined),
              onTap: () => onFriendTap(friend),
            ),
          ),
        ),
      ],
    );
  }
}
