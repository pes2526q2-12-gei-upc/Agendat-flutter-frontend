import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/utils/event_text_utils.dart';

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwnProfile ? 'Els meus interessos' : 'Interessos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOwnProfile)
                GestureDetector(
                  onTap: onEditTap,
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: EventTextUtils.kPrimaryRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text(
              'Cap interès afegit',
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
                      label: Text(i.name),
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
}
