/// Criteri d'ordenació de la llista de valoracions d'un esdeveniment.
enum ReviewSortCriterion {
  date,
  general,
  price,
  atmosphere,
  accessibility,
  reputation,
  likes,
}

extension ReviewSortCriterionLabels on ReviewSortCriterion {
  String get label => switch (this) {
    ReviewSortCriterion.date => 'Data',
    ReviewSortCriterion.general => 'Puntuació general',
    ReviewSortCriterion.price => 'Puntuació preu',
    ReviewSortCriterion.atmosphere => 'Puntuació ambient',
    ReviewSortCriterion.accessibility => 'Puntuació accessibilitat',
    ReviewSortCriterion.reputation => 'Reputació de l\'usuari',
    ReviewSortCriterion.likes => 'Nombre de likes',
  };

  /// Etiqueta del sentit d'ordenació ([descending] = primer els valors alts/recents).
  String directionLabel({required bool descending}) =>
      descending ? 'Descendent' : 'Ascendent';
}
