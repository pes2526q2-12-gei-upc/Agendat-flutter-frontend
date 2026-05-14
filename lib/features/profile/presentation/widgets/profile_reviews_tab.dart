import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';

class ProfileReviewsTab extends StatelessWidget {
  const ProfileReviewsTab({
    super.key,
    required this.response,
    required this.onReviewTap,
  });

  final UserReviewsResponse? response;
  final ValueChanged<UserReview> onReviewTap;

  @override
  Widget build(BuildContext context) {
    final reviews = response?.reviews ?? const <UserReview>[];
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'No hi ha ressenyes',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final r = reviews[index];
        return ListTile(
          onTap: () => onReviewTap(r),
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.rate_review, color: Colors.grey.shade600),
          title: Text(
            r.reviewerUsername.isEmpty ? 'Usuari' : r.reviewerUsername,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(r.comment.isEmpty ? '—' : r.comment),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '${r.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }
}
