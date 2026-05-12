import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/core/utils/chat_utils.dart';

/// Avatar circular amb foto de perfil ([resolveProfileImageUrl]) o inicials
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = resolveProfileImageUrl(profileImage);
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
      return initialsAvatar();
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          resolved,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => initialsAvatar(),
        ),
      ),
    );
  }
}
