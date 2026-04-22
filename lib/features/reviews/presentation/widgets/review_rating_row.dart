import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/rating_stars.dart';

/// Fila horitzontal amb una etiqueta a l'esquerra i estrelles a la dreta.
///
/// S'utilitza en dos contextos:
///   - Dins [ReviewCard] en mode lectura (estrelles petites, no editables).
///   - Dins [AddReviewForm] en mode edició (estrelles grans, on l'usuari
///     pot clicar-les per canviar la puntuació).
///
/// Si [onRatingChanged] és `null` la fila es pinta com a no editable.
class ReviewRatingRow extends StatelessWidget {
  const ReviewRatingRow({
    super.key,
    required this.label,
    required this.rating,
    this.onRatingChanged,
    this.labelWidth = 100,
    this.labelStyle,
    this.starSize = 14,
    this.starSpacing = 2,
    this.bottomSpacing = 4,
  });

  /// Text que s'escriu al costat de les estrelles (ex: "General", "Preu").
  final String label;

  /// Puntuació actual (de 0 a 5).
  final int rating;

  /// Callback quan l'usuari toca una estrella. Si és `null`, la fila no es
  /// pot editar i es pinta només de lectura.
  final ValueChanged<int>? onRatingChanged;

  /// Amplada reservada per a l'etiqueta; serveix perquè les estrelles
  /// quedin alineades encara que les etiquetes tinguin longituds diferents.
  final double labelWidth;

  /// Estil del text de l'etiqueta. Si és `null` es fa servir un estil neutre.
  final TextStyle? labelStyle;

  /// Mida de cada estrella i espai entre elles.
  final double starSize;
  final double starSpacing;

  /// Espai inferior després de la fila (per separar-la de la següent).
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final isEditable = onRatingChanged != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style:
                  labelStyle ??
                  const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          RatingStars(
            rating: rating,
            onRatingChanged: onRatingChanged ?? (_) {},
            isEnabled: isEditable,
            size: starSize,
            spacing: starSpacing,
          ),
        ],
      ),
    );
  }
}
