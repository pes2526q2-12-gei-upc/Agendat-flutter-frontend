import 'package:agendat/core/api/reviews_api.dart';
import 'package:agendat/core/dto/review_dto.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/profile/data/profile_api.dart'
    show fetchUserSessions;

export 'package:agendat/core/api/reviews_api.dart'
    show ReviewAlreadyExistsException, ReviewAttendanceRequiredException;

class SaveReviewResult {
  const SaveReviewResult({
    required this.review,
    required this.acceptedForModeration,
  });

  final Review review;
  final bool acceptedForModeration;
}

class ReviewsQuery {
  static final ReviewsQuery instance = ReviewsQuery._();
  ReviewsQuery._();

  final ReviewsApi _api = ReviewsApi();

  Future<List<Review>> fetchReviewsByEventCode(String eventCode) async {
    final dtos = await _api.fetchReviewsByEventCode(eventCode.trim());
    return dtos.map((dto) => dto.toModel()).toList(growable: false);
  }

  Future<SaveReviewResult> createReview({
    required String eventCode,
    required int general,
    required int preu,
    required int ambient,
    required int accessibilitat,
    String? comment,
  }) async {
    final dto = ReviewDto(
      eventCode: eventCode.trim(),
      general: general,
      preu: preu,
      ambient: ambient,
      accessibilitat: accessibilitat,
      comment: _normalizeComment(comment),
    );
    final saved = await _api.createReview(eventCode.trim(), dto);
    return SaveReviewResult(
      review: saved.toModel(),
      acceptedForModeration: saved.acceptedForModeration,
    );
  }

  Future<SaveReviewResult> updateReview({
    required String eventCode,
    required int reviewId,
    required int general,
    required int preu,
    required int ambient,
    required int accessibilitat,
    String? comment,
  }) async {
    final dto = ReviewDto(
      id: reviewId,
      eventCode: eventCode.trim(),
      general: general,
      preu: preu,
      ambient: ambient,
      accessibilitat: accessibilitat,
      comment: _normalizeComment(comment),
    );
    final saved = await _api.updateReview(eventCode.trim(), dto);
    return SaveReviewResult(
      review: saved.toModel(),
      acceptedForModeration: saved.acceptedForModeration,
    );
  }

  Future<void> deleteReview(String eventCode, int reviewId) =>
      _api.deleteReview(eventCode.trim(), reviewId);

  Future<void> likeReview(String eventCode, int reviewId) =>
      _api.likeReview(eventCode.trim(), reviewId);

  Future<void> unlikeReview(String eventCode, int reviewId) =>
      _api.unlikeReview(eventCode.trim(), reviewId);

  Future<bool> hasConfirmedAttendance({
    required String username,
    required String eventCode,
  }) async {
    final sessions = await fetchUserSessions(username: username);
    final now = DateTime.now();
    return sessions.any(
      (s) =>
          s.event == eventCode && s.endTime != null && s.endTime!.isBefore(now),
    );
  }

  String? _normalizeComment(String? comment) {
    final trimmed = comment?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
