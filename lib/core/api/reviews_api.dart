import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/review_dto.dart';

/// Client HTTP per a l'API de ressenyes d'un esdeveniment.
///
/// Endpoints:
///   - GET    /api/events/{eventCode}/reviews/            → llista de ressenyes
///   - POST   /api/events/{eventCode}/reviews/            → crear ressenya
///   - PATCH  /api/events/{eventCode}/reviews/{id}/       → editar ressenya
///   - DELETE /api/events/{eventCode}/reviews/{id}/       → eliminar ressenya
///   - POST   /api/events/{eventCode}/reviews/{id}/like/  → fer like
///   - DELETE /api/events/{eventCode}/reviews/{id}/like/  → treure like
///
/// Les ressenyes d'un usuari concret es consulten des de
/// `features/profile/data/profile_api.dart` (model diferent), no pas aquí.
class ReviewsApi {
  static String _eventReviewsPath(String eventCode) =>
      '/api/events/$eventCode/reviews/';

  static String _eventReviewPath(String eventCode, int reviewId) =>
      '/api/events/$eventCode/reviews/$reviewId/';

  static String _eventReviewLikePath(String eventCode, int reviewId) =>
      '/api/events/$eventCode/reviews/$reviewId/like/';

  /// Llista les ressenyes d'un esdeveniment.
  /// Si el backend retorna 404 (endpoint sense dades) es considera com a
  /// llista buida enlloc de propagar l'error.
  Future<List<ReviewDto>> fetchReviewsByEventCode(String eventCode) async {
    try {
      final response = await ApiClient.get(_eventReviewsPath(eventCode));
      return _parseReviewList(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const [];
      rethrow;
    }
  }

  /// Crea una nova ressenya per a [eventCode].
  Future<ReviewDto> createReview(String eventCode, ReviewDto review) async {
    final http.Response response;
    try {
      response = await ApiClient.postJson(
        _eventReviewsPath(eventCode),
        body: review.toCreateJson(),
        acceptedStatusCodes: const {200, 201, 202},
      );
    } on ApiException catch (e) {
      final attendance = _attendanceErrorFrom(e);
      if (attendance != null) throw attendance;
      final duplicate = _duplicateReviewErrorFrom(e);
      if (duplicate != null) throw duplicate;
      rethrow;
    }
    if (response.statusCode == 202) {
      // El backend ha acceptat la review per moderació, però encara no
      // retorna la review final publicada.
      return review.copyWith(acceptedForModeration: true);
    }

    final decoded = ApiClient.decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return ReviewDto.fromJson(decoded);
    }
    // Alguns backends no retornen el recurs creat; en aquest cas reutilitzem
    // el DTO enviat i deixem que el proper fetch sincronitzi la llista.
    debugPrint(
      'ReviewsApi.createReview: resposta sense JSON d\'objecte → ${response.body}',
    );
    return review;
  }

  /// Edita una ressenya existent. `review.id` ha d'estar definit.
  Future<ReviewDto> updateReview(String eventCode, ReviewDto review) async {
    final reviewId = review.id;
    if (reviewId == null) {
      throw ArgumentError('updateReview requires review.id to be set');
    }
    final http.Response response;
    try {
      response = await ApiClient.patchJson(
        _eventReviewPath(eventCode, reviewId),
        body: review.toUpdateJson(),
        acceptedStatusCodes: const {200, 202},
      );
    } on ApiException catch (e) {
      final attendance = _attendanceErrorFrom(e);
      if (attendance != null) throw attendance;
      rethrow;
    }
    if (response.statusCode == 202) {
      return review.copyWith(acceptedForModeration: true);
    }

    final decoded = ApiClient.decodeBody(response);
    if (decoded is Map<String, dynamic>) {
      return ReviewDto.fromJson(decoded);
    }
    debugPrint(
      'ReviewsApi.updateReview: resposta sense JSON d\'objecte → ${response.body}',
    );
    return review;
  }

  /// Elimina una ressenya.
  Future<void> deleteReview(String eventCode, int reviewId) async {
    await ApiClient.delete(
      _eventReviewPath(eventCode, reviewId),
      acceptedStatusCodes: const {200, 202, 204},
    );
  }

  /// Fa like a una ressenya.
  Future<void> likeReview(String eventCode, int reviewId) async {
    await ApiClient.postJson(
      _eventReviewLikePath(eventCode, reviewId),
      acceptedStatusCodes: const {200, 201, 204},
    );
  }

  /// Treu el like a una ressenya.
  Future<void> unlikeReview(String eventCode, int reviewId) async {
    await ApiClient.delete(
      _eventReviewLikePath(eventCode, reviewId),
      acceptedStatusCodes: const {200, 202, 204},
    );
  }

  /// Parser del format real del backend:
  /// `{ review_count, average_*, reviews: [...] }`.
  List<ReviewDto> _parseReviewList(http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) return const [];
    final decoded = jsonDecode(body);

    if (decoded is! Map<String, dynamic>) {
      debugPrint('ReviewsApi: format de resposta inesperat → ${response.body}');
      return const [];
    }

    final reviews = decoded['reviews'];
    if (reviews is! List) {
      debugPrint('ReviewsApi: falta el camp reviews → ${response.body}');
      return const [];
    }

    return reviews
        .whereType<Map<String, dynamic>>()
        .map(ReviewDto.fromJson)
        .toList(growable: false);
  }

  /// Detecta si una `ApiException` és causada perquè l'usuari no ha
  /// assistit a cap sessió de l'esdeveniment i, si és així, la converteix
  /// a una `ReviewAttendanceRequiredException` per que la UI la pugui
  /// tractar de manera específica.
  ReviewAttendanceRequiredException? _attendanceErrorFrom(ApiException e) {
    if (e.statusCode != 400 && e.statusCode != 403) return null;
    final body = e.body.toLowerCase();
    // Paraules clau esperades al missatge del backend. Afegir-ne més aquí
    // si apareixen altres variants.
    const attendanceKeywords = [
      'session has ended',
      'session has not ended',
      'first session',
      'attend',
      'assist',
    ];
    final matches = attendanceKeywords.any(body.contains);
    if (!matches) return null;

    // Intentem extreure el `detail` del JSON; si no hi és, fem servir el
    // body sencer com a missatge de fallback.
    String? detail;
    try {
      final decoded = jsonDecode(e.body);
      if (decoded is Map<String, dynamic>) {
        detail = decoded['detail'] as String?;
      }
    } catch (_) {
      // El body no és JSON; ho deixem com a null.
    }
    return ReviewAttendanceRequiredException(detail ?? e.body);
  }

  /// Detecta si una `ApiException` és causada perquè l'usuari ja té una
  /// valoració per aquest esdeveniment.
  ReviewAlreadyExistsException? _duplicateReviewErrorFrom(ApiException e) {
    if (e.statusCode != 400 && e.statusCode != 409) return null;
    final body = e.body.toLowerCase();
    const keywords = [
      'already reviewed',
      'already exists',
      'ja has valorat',
      'ja existeix',
    ];
    if (!keywords.any(body.contains)) return null;

    String? detail;
    try {
      final decoded = jsonDecode(e.body);
      if (decoded is Map<String, dynamic>) {
        detail = decoded['detail'] as String?;
      }
    } catch (_) {
      // El body no és JSON.
    }
    return ReviewAlreadyExistsException(detail ?? e.body);
  }
}

/// Es llança quan el backend rebutja la valoració perquè l'usuari encara
/// no ha assistit a l'esdeveniment.
class ReviewAttendanceRequiredException implements Exception {
  final String serverMessage;

  const ReviewAttendanceRequiredException(this.serverMessage);

  @override
  String toString() => 'ReviewAttendanceRequiredException: $serverMessage';
}

/// Es llança quan el backend rebutja la creació perquè l'usuari ja té
/// una valoració d'aquest esdeveniment.
class ReviewAlreadyExistsException implements Exception {
  final String serverMessage;

  const ReviewAlreadyExistsException(this.serverMessage);

  @override
  String toString() => 'ReviewAlreadyExistsException: $serverMessage';
}
