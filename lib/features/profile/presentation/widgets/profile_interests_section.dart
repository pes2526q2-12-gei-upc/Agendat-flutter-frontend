import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/l10n/app_localizations.dart';

class ProfileInterestsSection extends StatelessWidget {
  const ProfileInterestsSection({
    super.key,
    required this.isOwnProfile,
    required this.interests,
    required this.onEditTap,
  });

  final bool isOwnProfile;
  final List<UserInterest> interests;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isOwnProfile ? l10n.myInterestsTitle : l10n.interestsTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (isOwnProfile)
                TextButton.icon(
                  onPressed: onEditTap,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(l10n.editInterests),
                  style: TextButton.styleFrom(
                    foregroundColor: EventTextUtils.kPrimaryRed,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text(
              l10n.noInterestsAdded,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map(
                    (i) => Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _emojiForInterest(i),
                            style: const TextStyle(fontSize: 16, height: 1),
                          ),
                          const SizedBox(width: 6),
                          Text(i.name),
                        ],
                      ),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  String _emojiForInterest(UserInterest interest) {
    final emoji = interest.emoji;
    if (emoji != null && emoji.isNotEmpty) return emoji;
    return '✨';
  }
}
