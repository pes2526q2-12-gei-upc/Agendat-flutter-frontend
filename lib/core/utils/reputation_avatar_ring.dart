import 'package:flutter/material.dart';

class ReputationAvatarRingTier {
  const ReputationAvatarRingTier({
    required this.level,
    required this.maxInclusive,
    required this.color,
  });

  final int level;
  final double maxInclusive;
  final Color color;
}

const reputationAvatarRingTiers = <ReputationAvatarRingTier>[
  ReputationAvatarRingTier(
    level: 1,
    maxInclusive: 10,
    color: Color(0xFFB87333),
  ),
  ReputationAvatarRingTier(
    level: 2,
    maxInclusive: 30,
    color: Color(0xFFC0C0C0),
  ),
  ReputationAvatarRingTier(
    level: 3,
    maxInclusive: double.infinity,
    color: Color(0xFFD4AF37),
  ),
];

const Color reputationAvatarRingNeutralColor = Color(0xFFE0E0E0);

const int reputationAvatarRingNeutralLevel = 0;

const double reputationAvatarRingPadding = 6;
const double reputationAvatarRingBadgeSize = 18;
const double reputationAvatarRingBadgeTextSize = 10;

ReputationAvatarRingTier? reputationAvatarRingTierFor(double? reputation) {
  if (reputation == null || reputation.isNaN || !reputation.isFinite) {
    return null;
  }

  for (final tier in reputationAvatarRingTiers) {
    if (reputation <= tier.maxInclusive) {
      return tier;
    }
  }

  return reputationAvatarRingTiers.last;
}

Color reputationAvatarRingColor(double? reputation) {
  return reputationAvatarRingTierFor(reputation)?.color ??
      reputationAvatarRingNeutralColor;
}

int reputationAvatarRingLevel(double? reputation) {
  return reputationAvatarRingTierFor(reputation)?.level ??
      reputationAvatarRingNeutralLevel;
}

class ReputationAvatarRing extends StatelessWidget {
  const ReputationAvatarRing({
    super.key,
    required this.reputation,
    required this.child,
  });

  final double? reputation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tier = reputationAvatarRingTierFor(reputation);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(reputationAvatarRingPadding),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reputationAvatarRingColor(reputation),
          ),
          child: child,
        ),
        if (tier != null)
          Positioned(
            bottom: -reputationAvatarRingBadgeSize * 0.25,
            child: _ReputationLevelBadge(level: tier.level),
          ),
      ],
    );
  }
}

class _ReputationLevelBadge extends StatelessWidget {
  const _ReputationLevelBadge({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: reputationAvatarRingBadgeSize,
      height: reputationAvatarRingBadgeSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: const TextStyle(
          fontSize: reputationAvatarRingBadgeTextSize,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3A3A3A),
        ),
      ),
    );
  }
}
