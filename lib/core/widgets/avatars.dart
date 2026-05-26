import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/utils/reputation_avatar_ring.dart';

/// Avatar circular amb foto de perfil ([chatProfileImageUrl]) o inicials
/// ([chatAvatarInitials]). Compatible amb web (`Image.network`).
class ProfileCircleAvatar extends StatelessWidget {
  const ProfileCircleAvatar({
    super.key,
    required this.radius,
    this.profileImage,
    required this.fallbackLabel,
    this.fallback,
    this.reputation,
    this.userId,
    this.showLevelRing = false,
  });

  final double radius;
  final String? profileImage;
  final String? fallbackLabel;
  final Widget? fallback;
  final double? reputation;
  final int? userId;
  final bool showLevelRing;

  /// Clau estable per evitar que `ListView` reutilitzi la imatge d’un altre usuari.
  static ValueKey<String> imageKey({
    required String? profileImage,
    required String? fallbackLabel,
  }) {
    final resolved = chatProfileImageUrl(profileImage);
    final initials = chatAvatarInitials(fallbackLabel);
    return ValueKey<String>(
      resolved == null ? 'initials:$initials' : 'url:$resolved',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = chatProfileImageUrl(profileImage);
    final avatarKey = imageKey(
      profileImage: profileImage,
      fallbackLabel: fallbackLabel,
    );
    final size = radius * 2;
    final label = chatAvatarInitials(fallbackLabel);
    final textStyle =
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: radius * 0.62,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          fontSize: radius * 0.62,
        );

    Widget initialsAvatar() =>
        fallback ??
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade300,
          child: Text(label, style: textStyle),
        );

    final avatar = resolved == null
        ? KeyedSubtree(key: avatarKey, child: initialsAvatar())
        : KeyedSubtree(
            key: avatarKey,
            child: ClipOval(
              child: SizedBox(
                width: size,
                height: size,
                child: Image.network(
                  resolved,
                  key: avatarKey,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  webHtmlElementStrategy: kIsWeb
                      ? WebHtmlElementStrategy.prefer
                      : WebHtmlElementStrategy.never,
                  errorBuilder: (_, __, ___) => initialsAvatar(),
                ),
              ),
            ),
          );

    return AvatarLevelRing(
      enabled: showLevelRing,
      reputation: reputation,
      userId: userId,
      child: avatar,
    );
  }
}

class AvatarLevelRing extends StatelessWidget {
  const AvatarLevelRing({
    super.key,
    required this.child,
    this.reputation,
    this.userId,
    this.enabled = true,
    this.showNeutralRingWhenUnknown = true,
  });

  final Widget child;
  final double? reputation;
  final int? userId;
  final bool enabled;
  final bool showNeutralRingWhenUnknown;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    if (reputation != null) {
      return ReputationAvatarRing(reputation: reputation, child: child);
    }

    if (userId == null) {
      if (!showNeutralRingWhenUnknown) return child;
      return ReputationAvatarRing(reputation: null, child: child);
    }

    return _DeferredAvatarLevelRing(
      userId: userId!,
      child: child,
      showNeutralRingWhenUnknown: showNeutralRingWhenUnknown,
    );
  }
}

class _DeferredAvatarLevelRing extends StatefulWidget {
  const _DeferredAvatarLevelRing({
    required this.userId,
    required this.child,
    required this.showNeutralRingWhenUnknown,
  });

  final int userId;
  final Widget child;
  final bool showNeutralRingWhenUnknown;

  @override
  State<_DeferredAvatarLevelRing> createState() =>
      _DeferredAvatarLevelRingState();
}

class _DeferredAvatarLevelRingState extends State<_DeferredAvatarLevelRing> {
  late Future<double?> _reputationFuture;

  @override
  void initState() {
    super.initState();
    _reputationFuture = _loadReputation();
  }

  @override
  void didUpdateWidget(covariant _DeferredAvatarLevelRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _reputationFuture = _loadReputation();
    }
  }

  Future<double?> _loadReputation() {
    return ProfileQuery.instance.getUserReputation(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double?>(
      future: _reputationFuture,
      builder: (context, snapshot) {
        final resolvedReputation = snapshot.data;
        final shouldShowNeutral =
            widget.showNeutralRingWhenUnknown || resolvedReputation != null;

        if (!shouldShowNeutral) return widget.child;

        return ReputationAvatarRing(
          reputation: resolvedReputation,
          child: widget.child,
        );
      },
    );
  }
}
