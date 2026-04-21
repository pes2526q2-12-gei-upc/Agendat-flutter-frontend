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
    this.comment,
    this.imageUrls = const [],
  });

  /// Identificador a la BBDD. És `null` per a valoracions encara no
  /// persistides (p. ex. dades mock o formularis de creació).
  final int? id;
  final String author;
  final int general;
  final int preu;
  final int ambient;
  final int accessibilitat;
  final String? comment;
  final List<String> imageUrls;
  final String date;

  Review copyWith({
    int? id,
    int? general,
    int? preu,
    int? ambient,
    int? accessibilitat,
    String? comment,
    List<String>? imageUrls,
    String? date,
  }) {
    return Review(
      id: id ?? this.id,
      author: author,
      general: general ?? this.general,
      preu: preu ?? this.preu,
      ambient: ambient ?? this.ambient,
      accessibilitat: accessibilitat ?? this.accessibilitat,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      date: date ?? this.date,
    );
  }
}
