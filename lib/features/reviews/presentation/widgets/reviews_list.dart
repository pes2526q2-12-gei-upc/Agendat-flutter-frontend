import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_card.dart';

/// Llista de valoracions d'un esdeveniment.
///
/// Comença mostrant [initialLimit] valoracions i ofereix un botó
/// "Mostrar més" per carregar-ne més de [initialLimit] en [initialLimit].
/// Un cop l'usuari n'ha desplegat alguna, apareix també "Mostrar menys"
/// per tornar a l'estat inicial.
///
/// Si [currentUsername] coincideix amb l'autor d'alguna valoració i es
/// passa [onEditReview], a aquella valoració s'hi mostra el botó d'editar.
class ReviewsList extends StatefulWidget {
  const ReviewsList({
    super.key,
    required this.reviews,
    this.initialLimit = 3,
    this.currentUsername,
    this.onEditReview,
  });

  final List<Review> reviews;
  final int initialLimit;
  final String? currentUsername;

  /// Es crida quan l'usuari prem el llapis d'una valoració seva.
  /// Rep l'índex dins de [reviews] per localitzar-la.
  /// Si és `null` mai es mostra el botó d'editar
  final void Function(int index)? onEditReview;

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  late int _visibleCount = widget.initialLimit;

  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);

  void _showMore() => setState(() => _visibleCount += widget.initialLimit);

  void _showLess() => setState(() => _visibleCount = widget.initialLimit);

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return _buildEmptyState();

    final visibleReviews = widget.reviews.take(_visibleCount).toList();
    final hasMore = widget.reviews.length > _visibleCount;
    final canCollapse =
        _visibleCount > widget.initialLimit &&
        widget.reviews.length > widget.initialLimit;

    return Column(
      children: [
        for (int i = 0; i < visibleReviews.length; i++)
          ReviewCard(
            review: visibleReviews[i],
            onEdit: _canEdit(visibleReviews[i])
                ? () => widget.onEditReview!(i)
                : null,
          ),
        if (hasMore) _buildTextButton('Mostrar més', _showMore),
        if (canCollapse) _buildTextButton('Mostrar menys', _showLess),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Una valoració es pot editar només si és de l'usuari loggejat i
  /// el pare ens ha proporcionat un callback d'edició.
  bool _canEdit(Review review) {
    return widget.onEditReview != null &&
        widget.currentUsername != null &&
        review.author == widget.currentUsername;
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'No hi ha valoracions d\'aquest esdeveniment.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.black54),
      ),
    );
  }

  Widget _buildTextButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(color: _brandRed)),
    );
  }
}
