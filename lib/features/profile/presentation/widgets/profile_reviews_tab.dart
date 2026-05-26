import 'package:flutter/material.dart';

import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';
import 'package:agendat/l10n/app_localizations.dart';

class ProfileReviewsTab extends StatelessWidget {
  const ProfileReviewsTab({
    super.key,
    required this.response,
    required this.eventsQuery,
    required this.onReviewTap,
  });

  final UserReviewsResponse? response;
  final EventsQuery eventsQuery;
  final ValueChanged<UserReview> onReviewTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              l10n.profileNoReviews,
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
        final review = reviews[index];
        final comment = review.comment.trim();
        return InkWell(
          onTap: () => onReviewTap(review),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileReviewRatingRow(
                        review: review,
                        eventsQuery: eventsQuery,
                      ),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          comment,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileReviewRatingRow extends StatelessWidget {
  const _ProfileReviewRatingRow({
    required this.review,
    required this.eventsQuery,
  });

  final UserReview review;
  final EventsQuery eventsQuery;

  @override
  Widget build(BuildContext context) {
    final cachedTitle = review.eventTitle?.trim();
    if (cachedTitle != null && cachedTitle.isNotEmpty) {
      return _buildRatingRow(cachedTitle);
    }

    final eventCode = review.eventCode?.trim();
    if (eventCode == null || eventCode.isEmpty) {
      return _buildRatingRow(
        AppLocalizations.of(context).profileReviewFallbackEvent,
      );
    }

    return FutureBuilder(
      future: eventsQuery.getEventByCode(eventCode),
      builder: (context, snapshot) {
        final title = snapshot.data?.title.trim();
        final display = (title == null || title.isEmpty) ? eventCode : title;
        return _buildRatingRow(display);
      },
    );
  }

  Widget _buildRatingRow(String label) {
    return ReviewRatingRow(
      label: label,
      rating: review.rating,
      labelWidth: 130,
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      starSize: ReviewRatingRow.cardGeneralStarSize,
      starSpacing: 3,
      bottomSpacing: 0,
    );
  }
}
