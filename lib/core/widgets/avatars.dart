import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/utils/chat_utils.dart';

/// Avatar circular amb foto de perfil ([chatProfileImageUrl]) o inicials
/// ([chatAvatarInitials]). Compatible amb web (`Image.network`).
class ProfileCircleAvatar extends StatelessWidget {
  const ProfileCircleAvatar({
    super.key,
    required this.radius,
    this.profileImage,
    required this.fallbackLabel,
  });

  final double radius;
  final String? profileImage;
  final String? fallbackLabel;

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

    Widget initialsAvatar() => CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade300,
      child: Text(label, style: textStyle),
    );

    if (resolved == null) {
      return KeyedSubtree(key: avatarKey, child: initialsAvatar());
    }

    return KeyedSubtree(
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
  }
}
