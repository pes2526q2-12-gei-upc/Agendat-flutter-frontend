import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/utils/profile_image_url.dart';

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    const radius = 26.0;
    const size = radius * 2;
    final imageUrl = resolveProfileImageUrl(profileImage);

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 28, color: Colors.grey.shade400),
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
            child: Icon(Icons.person, size: 28, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
