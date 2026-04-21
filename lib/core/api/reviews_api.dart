import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/review_dto.dart';

/// Client HTTP per a l'API de ressenyes.
///
/// Endpoints (TODO(backend): confirmar rutes exactes amb el servidor):
///   - GET    /api/events/{eventCode}/reviews/            → llista de ressenyes
///   - POST   /api/events/{eventCode}/reviews/            → crear ressenya
///   - PATCH  /api/events/{eventCode}/reviews/{id}/       → editar ressenya
///   - DELETE /api/events/{eventCode}/reviews/{id}/       → eliminar ressenya
///   - POST   /api/events/{eventCode}/reviews/{id}/like/  → fer like
///   - DELETE /api/events/{eventCode}/reviews/{id}/like/  → treure like
///   - GET    /api/users/{userId}/reviews/                → ressenyes d'un usuari
class ReviewsApi {
  static String _eventReviewsPath(String eventCode) =>
      '/api/events/$eventCode/reviews/';

  static String _eventReviewPath(String eventCode, int reviewId) =>
      '/api/events/$eventCode/reviews/$reviewId/';

  static String _eventReviewLikePath(String eventCode, int reviewId) =>
      '/api/events/$eventCode/reviews/$reviewId/like/';

  static String _userReviewsPath(String userId) =>
      '/api/users/$userId/reviews/';

  /// Llista les ressenyes d'un esdeveniment.
  Future<List<ReviewDto>> fetchReviewsByEventCode(String eventCode) async {
    final response = await ApiClient.get(_eventReviewsPath(eventCode));
    final jsonList = ApiClient.decodeListBody(response);
    return jsonList.map(ReviewDto.fromJson).toList(growable: false);
  }

  /// Llista les ressenyes que ha fet un usuari.
  Future<List<ReviewDto>> fetchReviewsByUserId(String userId) async {
    final response = await ApiClient.get(_userReviewsPath(userId));
    final jsonList = ApiClient.decodeListBody(response);
    return jsonList.map(ReviewDto.fromJson).toList(growable: false);
  }

  /// Crea una nova ressenya per a [eventCode].
  Future<ReviewDto> createReview(String eventCode, ReviewDto review) async {
    final response = await ApiClient.postJson(
      _eventReviewsPath(eventCode),
      body: review.toCreateJson(),
      expectedStatusCode: 201,
    );
    final decoded = ApiClient.decodeBody(response) as Map<String, dynamic>;
    return ReviewDto.fromJson(decoded);
  }

  /// Edita una ressenya existent. `review.id` ha d'estar definit.
  Future<ReviewDto> updateReview(String eventCode, ReviewDto review) async {
    final reviewId = review.id;
    if (reviewId == null) {
      throw ArgumentError('updateReview requires review.id to be set');
    }
    final response = await ApiClient.patchJson(
      _eventReviewPath(eventCode, reviewId),
      body: review.toUpdateJson(),
    );
    final decoded = ApiClient.decodeBody(response) as Map<String, dynamic>;
    return ReviewDto.fromJson(decoded);
  }

  /// Elimina una ressenya.
  Future<void> deleteReview(String eventCode, int reviewId) async {
    await ApiClient.delete(_eventReviewPath(eventCode, reviewId));
  }

  /// Fa like a una ressenya.
  Future<void> likeReview(String eventCode, int reviewId) async {
    await ApiClient.postJson(
      _eventReviewLikePath(eventCode, reviewId),
      expectedStatusCode: 201,
    );
  }

  /// Treu el like a una ressenya.
  Future<void> unlikeReview(String eventCode, int reviewId) async {
    await ApiClient.delete(_eventReviewLikePath(eventCode, reviewId));
  }
}
