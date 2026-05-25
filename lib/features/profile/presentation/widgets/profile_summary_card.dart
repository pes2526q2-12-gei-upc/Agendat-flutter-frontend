import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/reputation_avatar_ring.dart';
import 'package:agendat/core/utils/profile_image_url.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.stats,
    this.attendanceCount,
    this.reviewsCount,
    required this.isOwnProfile,
    required this.onEditProfile,
    required this.friendshipSection,
  });

  final UserProfile profile;
  final UserStats? stats;

  /// Assistències confirmades (sessions). Si és `null`, es fa servir [stats].
  final int? attendanceCount;

  /// Ressenyes del perfil (mateixa font que la pestanya). Si és `null`, stats.
  final int? reviewsCount;
  final bool isOwnProfile;
  final VoidCallback onEditProfile;
  final Widget friendshipSection;

  @override
  Widget build(BuildContext context) {
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileViewAvatar(profile: profile),
              const SizedBox(width: 16),
              Expanded(
                child: _ProfileInfoHeader(
                  profile: profile,
                  reputation: profile.reputacio,
                ),
              ),
              if (isOwnProfile)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                  onPressed: onEditProfile,
                ),
            ],
          ),
          // Stats row removed per request
          if (!isOwnProfile) ...[const SizedBox(height: 16), friendshipSection],
        ],
      ),
    );
  }
}

class _ProfileViewAvatar extends StatelessWidget {
  const _ProfileViewAvatar({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveProfileImageUrl(profile.profileImage);
    const radius = 47.0;
    const size = radius * 2;

    final avatar = imageUrl == null
        ? CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
            child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
          )
        : ClipOval(
            child: SizedBox(
              width: size,
              height: size,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                webHtmlElementStrategy: kIsWeb
                    ? WebHtmlElementStrategy.prefer
                    : WebHtmlElementStrategy.never,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  );
                },
              ),
            ),
          );

    return ReputationAvatarRing(reputation: profile.reputacio, child: avatar);
  }
}

class _ProfileInfoHeader extends StatelessWidget {
  const _ProfileInfoHeader({required this.profile, required this.reputation});

  final UserProfile profile;
  final double? reputation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _ReputationChip(
          reputation: reputation,
          tierName: reputationAvatarRingTierName(reputation),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                profile.displayDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReputationChip extends StatelessWidget {
  const _ReputationChip({required this.reputation, required this.tierName});

  final double? reputation;
  final String tierName;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 16, color: Colors.amber.shade700),
              const SizedBox(width: 4),
              Text(
                reputation == null ? '—' : reputation!.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          tierName,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
