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
/// passen els callbacks d'edició/esborrat, a aquella valoració s'hi
/// mostren els botons corresponents.
class ReviewsList extends StatefulWidget {
  const ReviewsList({
    super.key,
    required this.reviews,
    this.initialLimit = 3,
    this.currentUsername,
    this.onEditReview,
    this.onDeleteReview,
    this.onToggleLike,
    this.busyLikeIds = const {},
  });

  final List<Review> reviews;
  final int initialLimit;
  final String? currentUsername;

  /// Es crida quan l'usuari prem el llapis d'una valoració seva.
  /// Rep l'índex dins de [reviews] per localitzar-la.
  /// Si és `null` mai es mostra el botó d'editar.
  final void Function(int index)? onEditReview;

  /// Es crida quan l'usuari prem la paperera d'una valoració seva.
  /// Rep la `Review` per localitzar-la. Si és `null` mai es mostra el
  /// botó d'eliminar.
  final void Function(Review review)? onDeleteReview;

  /// Es crida quan l'usuari prem el cor d'una valoració per alternar el
  /// seu like. Si és `null` el botó queda deshabilitat.
  final void Function(Review review)? onToggleLike;

  /// Conjunt d'`id` de valoracions amb una petició de like/unlike en curs
  /// per deshabilitar el botó i evitar doble click.
  final Set<int> busyLikeIds;

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
            onEdit: _canMutate(visibleReviews[i]) && widget.onEditReview != null
                ? () => widget.onEditReview!(i)
                : null,
            onDelete:
                _canMutate(visibleReviews[i]) && widget.onDeleteReview != null
                ? () => widget.onDeleteReview!(visibleReviews[i])
                : null,
            onLikeToggle: widget.onToggleLike == null
                ? null
                : () => widget.onToggleLike!(visibleReviews[i]),
            isLikeBusy:
                visibleReviews[i].id != null &&
                widget.busyLikeIds.contains(visibleReviews[i].id),
          ),
        if (hasMore) _buildTextButton('Mostrar més', _showMore),
        if (canCollapse) _buildTextButton('Mostrar menys', _showLess),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Una valoració només es pot editar/esborrar si és de l'usuari loggejat.
  bool _canMutate(Review review) {
    return widget.currentUsername != null &&
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
