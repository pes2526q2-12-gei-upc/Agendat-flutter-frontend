/// Model d'una valoració (ressenya) d'un esdeveniment.
///
/// De moment només es fa servir amb dades mock dins la UI.
/// TODO(backend): quan existeixi l'API de ressenyes, afegir un camp `id`
/// (identificador a la BBDD) i els mètodes `fromJson` / `toJson` per
/// serialitzar la valoració quan es parli amb el servidor.
class Review {
  const Review({
    required this.author,
    required this.general,
    required this.preu,
    required this.ambient,
    required this.accessibilitat,
    required this.date,
    this.comment,
    this.imageUrls = const [],
  });

  final String author;
  final int general;
  final int preu;
  final int ambient;
  final int accessibilitat;
  final String? comment; //opcional
  final List<String> imageUrls; //opcional
  final String date;

  Review copyWith({
    int? general,
    int? preu,
    int? ambient,
    int? accessibilitat,
    String? comment,
    List<String>? imageUrls,
    String? date,
  }) {
    return Review(
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
