/// Model d'una valoració (ressenya) d'un esdeveniment.
///
/// És el model de domini que consumeix la UI. La serialització HTTP es fa
/// a `ReviewDto` (veure `lib/core/dto/review_dto.dart`) i es converteix a
/// aquest model mitjançant `ReviewDto.toModel()`.
class Review {
  const Review({
    required this.author,
    required this.general,
    required this.preu,
    required this.ambient,
    required this.accessibilitat,
    required this.date,
    this.id,
    this.authorAvatarUrl,
    this.comment,
    this.imageUrls = const [],
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  /// Identificador a la BBDD. És `null` per a valoracions encara no
  /// persistides (p. ex. dades mock o formularis de creació).
  final int? id;
  final String author;

  /// URL de la foto de perfil de l'autor (si el backend la proporciona).
  /// Si és `null`/buida, la targeta pintarà la inicial com a fallback.
  final String? authorAvatarUrl;
  final int general;
  final int preu;
  final int ambient;
  final int accessibilitat;
  final String? comment;
  final List<String> imageUrls;
  final String date;
  final int likesCount;
  final bool isLikedByMe;

  Review copyWith({
    int? id,
    String? author,
    String? authorAvatarUrl,
    int? general,
    int? preu,
    int? ambient,
    int? accessibilitat,
    String? comment,
    List<String>? imageUrls,
    String? date,
    int? likesCount,
    bool? isLikedByMe,
  }) {
    return Review(
      id: id ?? this.id,
      author: author ?? this.author,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      general: general ?? this.general,
      preu: preu ?? this.preu,
      ambient: ambient ?? this.ambient,
      accessibilitat: accessibilitat ?? this.accessibilitat,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      date: date ?? this.date,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}
