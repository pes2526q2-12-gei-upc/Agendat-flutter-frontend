import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/reviews/presentation/helpers/reviews_section_helpers.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';

/// Mitjanes de les quatre categories sota el títol VALORACIONS.
class ReviewsAverageSummary extends StatelessWidget {
  const ReviewsAverageSummary({
    super.key,
    required this.reviews,
    required this.isLoadingWhenListEmpty,
  });

  final List<Review> reviews;
  final bool isLoadingWhenListEmpty;

  static const double _summaryGeneralStarSize = 24;
  static const double _summaryOtherStarSize = 20;

  static const TextStyle _labelStyle = TextStyle(
    fontSize: 14,
    color: Colors.black87,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    if (isLoadingWhenListEmpty && reviews.isEmpty) {
      return const Text(
        'Carregant valoracions...',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }
    if (reviews.isEmpty) {
      return const Text(
        'Encara no hi ha valoracions.',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }

    final generalAvg = reviewRatingAverage(reviews, (r) => r.general);
    final preuAvg = reviewRatingAverage(reviews, (r) => r.preu);
    final ambientAvg = reviewRatingAverage(reviews, (r) => r.ambient);
    final accessAvg = reviewRatingAverage(reviews, (r) => r.accessibilitat);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewRatingRow(
          label: 'General (${formatReviewAverageLabel(generalAvg)})',
          rating: generalAvg,
          labelWidth: 130,
          labelStyle: _labelStyle,
          starSize: _summaryGeneralStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Preu (${formatReviewAverageLabel(preuAvg)})',
          rating: preuAvg,
          labelWidth: 130,
          labelStyle: _labelStyle,
          starSize: _summaryOtherStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Ambient (${formatReviewAverageLabel(ambientAvg)})',
          rating: ambientAvg,
          labelWidth: 130,
          labelStyle: _labelStyle,
          starSize: _summaryOtherStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Accessibilitat (${formatReviewAverageLabel(accessAvg)})',
          rating: accessAvg,
          labelWidth: 130,
          labelStyle: _labelStyle,
          starSize: _summaryOtherStarSize,
          bottomSpacing: 0,
        ),
      ],
    );
  }
}
