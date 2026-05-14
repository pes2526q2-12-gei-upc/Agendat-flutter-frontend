import 'package:agendat/core/models/review.dart';

/// Mitjana d'una puntuació entera per a totes les valoracions de [reviews].
/// Retorna 0 si la llista és buida.
double reviewRatingAverage(
  List<Review> reviews,
  int Function(Review r) selector,
) {
  if (reviews.isEmpty) return 0;
  final sum = reviews.fold<int>(0, (acc, r) => acc + selector(r));
  return (sum / reviews.length).clamp(0, 5);
}

/// Mostra fins a un decimal, sense ".0" si és un enter.
String formatReviewAverageLabel(double value) {
  final roundedToOneDecimal = (value * 10).round() / 10;
  final oneDecimal = roundedToOneDecimal.toStringAsFixed(1);
  return oneDecimal.endsWith('.0')
      ? oneDecimal.substring(0, oneDecimal.length - 2)
      : oneDecimal;
}

/// Si l'usuari té una valoració dins [reviews] i no està ja al principi,
/// la mou a la posició 0. Muta la llista rebuda.
void pinOwnReviewFirst(
  List<Review> reviews,
  bool Function(Review) isOwnReview,
) {
  final idx = reviews.indexWhere(isOwnReview);
  if (idx > 0) {
    final mine = reviews.removeAt(idx);
    reviews.insert(0, mine);
  }
}

/// Duas valoracions pròpies coincideixen en les quatre puntuacions.
bool sameOwnReviewByRatings(
  Review a,
  Review b,
  bool Function(Review) isOwnReview,
) {
  return isOwnReview(a) &&
      isOwnReview(b) &&
      a.general == b.general &&
      a.preu == b.preu &&
      a.ambient == b.ambient &&
      a.accessibilitat == b.accessibilitat;
}

/// Conserva valoracions pròpies sense `id` (p. ex. pendent de sync) si encara
/// no apareixen a [serverMerged]. Muta [serverMerged].
void mergePendingOwnReviewsWithoutServerId({
  required List<Review> previousList,
  required List<Review> serverMerged,
  required bool Function(Review) isOwnReview,
  required bool Function(Review a, Review b) sameOwnByRatings,
}) {
  final pending = previousList.where((r) => isOwnReview(r) && r.id == null);
  for (final review in pending) {
    final alreadyPublished = serverMerged.any(
      (serverReview) => sameOwnByRatings(serverReview, review),
    );
    if (!alreadyPublished) {
      serverMerged.insert(0, review);
    }
  }
}

/// Completa una review de l'usuari actual quan el backend torna una resposta
/// parcial (autor, avatar, comentari, etc.).
Review mergeSavedReviewWithViewerProfile({
  required Review saved,
  required String? viewerUserId,
  required String? viewerUsername,
  required String? viewerAvatarUrl,
  Review? existing,
  String? submittedComment,
  bool hideSubmittedComment = false,
  DateTime? nowUtc,
}) {
  final clock = nowUtc ?? DateTime.now().toUtc();

  String author;
  if (viewerUsername != null && viewerUsername.isNotEmpty) {
    author = viewerUsername;
  } else if (saved.author.trim().isNotEmpty) {
    author = saved.author;
  } else {
    author = existing?.author ?? '';
  }

  final fromServerAvatar = saved.authorAvatarUrl?.trim();
  final hasServerAvatar =
      fromServerAvatar != null && fromServerAvatar.isNotEmpty;
  final avatarUrl = hasServerAvatar
      ? saved.authorAvatarUrl
      : (existing?.authorAvatarUrl ?? viewerAvatarUrl);

  String? comment = hideSubmittedComment ? null : saved.comment;
  if (!hideSubmittedComment && (comment == null || comment.trim().isEmpty)) {
    final fallbackComment = submittedComment?.trim();
    if (fallbackComment != null && fallbackComment.isNotEmpty) {
      comment = fallbackComment;
    } else if (existing?.comment != null &&
        existing!.comment!.trim().isNotEmpty) {
      comment = existing.comment;
    } else {
      comment = null;
    }
  }

  final imageUrls = saved.imageUrls.isNotEmpty
      ? saved.imageUrls
      : (existing?.imageUrls ?? const <String>[]);

  final date = saved.date.trim().isNotEmpty
      ? saved.date
      : (existing != null && existing.date.trim().isNotEmpty
            ? existing.date
            : clock.toIso8601String());

  return Review(
    id: saved.id ?? existing?.id,
    authorId: saved.authorId ?? existing?.authorId ?? viewerUserId,
    author: author,
    authorAvatarUrl: avatarUrl,
    general: saved.general,
    preu: saved.preu,
    ambient: saved.ambient,
    accessibilitat: saved.accessibilitat,
    comment: comment,
    imageUrls: imageUrls,
    date: date,
    likesCount: saved.likesCount,
    isLikedByMe: saved.isLikedByMe,
  );
}
