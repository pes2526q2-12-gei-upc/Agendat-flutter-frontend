import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/avatars.dart';

class SocialAvatar extends StatelessWidget {
  const SocialAvatar({
    super.key,
    required this.profileImage,
    this.userId,
    this.reputation,
  });

  final String? profileImage;
  final int? userId;
  final double? reputation;

  @override
  Widget build(BuildContext context) {
    return ProfileCircleAvatar(
      radius: 26,
      profileImage: profileImage,
      fallbackLabel: null,
      fallback: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 28, color: Colors.grey.shade400),
      ),
      userId: userId,
      reputation: reputation,
      showLevelRing: true,
    );
  }
}
