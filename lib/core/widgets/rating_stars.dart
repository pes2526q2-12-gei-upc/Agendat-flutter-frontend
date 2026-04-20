import 'package:flutter/material.dart';

/// Fila d'estrelles per mostrar o demanar una puntuació (de 0 a `maxStars`).
///
/// - Si [isEnabled] és `true`, tocar una estrella canvia la valoració i
///   es notifica a [onRatingChanged] amb el nou valor.
/// - Si [isEnabled] és `false`, les estrelles es mostren només de lectura
///   (p. ex. a les targetes de ressenya ja enviades).
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.maxStars = 5,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.size = 28,
    this.spacing = 4,
    this.isEnabled = true,
  }) : assert(rating >= 0),
       assert(maxStars > 0),
       assert(rating <= maxStars);

  final int rating;
  final ValueChanged<int> onRatingChanged;
  final int maxStars;
  final Color activeColor;
  final Color inactiveColor;
  final double size;
  final double spacing;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        final starValue = index + 1;
        final isActive = starValue <= rating;

        return Padding(
          padding: EdgeInsets.only(right: index == maxStars - 1 ? 0 : spacing),
          child: InkWell(
            borderRadius: BorderRadius.circular(size),
            onTap: isEnabled ? () => onRatingChanged(starValue) : null,
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_border_rounded,
              color: isActive ? activeColor : inactiveColor,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}
