import 'package:agendat/core/api/reviews_api.dart';
import 'package:agendat/core/dto/review_dto.dart';
import 'package:agendat/core/mappers/reviews_mapper.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/query/sessions_query.dart';

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

class ReviewTranslationResult {
  const ReviewTranslationResult({
    required this.reviewId,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.originalComment,
    required this.translatedComment,
  });

  final int reviewId;
  final String sourceLanguage;
  final String targetLanguage;
  final String originalComment;
  final String translatedComment;

  factory ReviewTranslationResult.fromJson(Map<String, dynamic> json) {
    return ReviewTranslationResult(
      reviewId: (json['review_id'] as num?)?.toInt() ?? 0,
      sourceLanguage: (json['source_language'] as String? ?? '').trim(),
      targetLanguage: (json['target_language'] as String? ?? '').trim(),
      originalComment: (json['original_comment'] as String? ?? '').trim(),
      translatedComment: (json['translated_comment'] as String? ?? '').trim(),
    );
  }
}

class ReviewsQuery {
  static final ReviewsQuery instance = ReviewsQuery._();
  ReviewsQuery._();

  final ReviewsApi _api = ReviewsApi();

  Future<List<Review>> fetchReviewsByEventCode(String eventCode) async {
    final dtos = await _api.fetchReviewsByEventCode(eventCode.trim());
    return dtos.map((dto) => dto.toDomain()).toList(growable: false);
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
      review: saved.toDomain(),
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
      review: saved.toDomain(),
      acceptedForModeration: saved.acceptedForModeration,
    );
  }

  Future<void> deleteReview(String eventCode, int reviewId) =>
      _api.deleteReview(eventCode.trim(), reviewId);

  Future<void> likeReview(String eventCode, int reviewId) =>
      _api.likeReview(eventCode.trim(), reviewId);

  Future<void> unlikeReview(String eventCode, int reviewId) =>
      _api.unlikeReview(eventCode.trim(), reviewId);

  Future<bool> hasConfirmedAttendance({required String eventCode}) async {
    // Les sessions de l'usuari autenticat venen de GET /api/sessions/
    // (sense query); el backend rebutja ?user=<username> amb 400.
    final sessions = await SessionsQuery.instance.getSessions();
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

  Future<ReviewTranslationResult?> translateReview(
    String eventCode,
    int reviewId,
    String language,
  ) async {
    final raw = await _api.translateReview(
      eventCode.trim(),
      reviewId,
      language,
    );
    if (raw == null) return null;
    return ReviewTranslationResult.fromJson(raw);
  }
}
