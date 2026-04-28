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
/// Si la valoració és de l'usuari actual, es mostren editar i eliminar.
class ReviewsList extends StatefulWidget {
  const ReviewsList({
    super.key,
    required this.reviews,
    this.initialLimit = 3,
    this.currentUserId,
    this.onEditReview,
    this.onDeleteReview,
    this.onToggleLike,
    this.busyLikeIds = const {},
  });

  final List<Review> reviews;
  final int initialLimit;
  final String? currentUserId;

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

    final orderedReviews = _orderedReviews();
    final visibleReviews = orderedReviews.take(_visibleCount).toList();
    final hasMore = orderedReviews.length > _visibleCount;
    final canCollapse =
        _visibleCount > widget.initialLimit &&
        orderedReviews.length > widget.initialLimit;

    return Column(
      children: [
        for (int i = 0; i < visibleReviews.length; i++)
          ReviewCard(
            review: visibleReviews[i].review,
            onEdit:
                _isOwnReview(visibleReviews[i].review) &&
                    widget.onEditReview != null
                ? () => widget.onEditReview!(visibleReviews[i].originalIndex)
                : null,
            onDelete:
                _isOwnReview(visibleReviews[i].review) &&
                    widget.onDeleteReview != null
                ? () => widget.onDeleteReview!(visibleReviews[i].review)
                : null,
            onLikeToggle: widget.onToggleLike == null
                ? null
                : () => widget.onToggleLike!(visibleReviews[i].review),
            isLikeBusy:
                visibleReviews[i].review.id != null &&
                widget.busyLikeIds.contains(visibleReviews[i].review.id),
          ),
        if (hasMore) _buildTextButton('Mostrar més', _showMore),
        if (canCollapse) _buildTextButton('Mostrar menys', _showLess),
        const SizedBox(height: 8),
      ],
    );
  }

  String? get _normalizedCurrentUserId {
    final raw = widget.currentUserId?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  /// Comparem l'id de l'usuari loggejat amb `reviewer_id`.
  bool _isOwnReview(Review review) {
    final currentUserId = _normalizedCurrentUserId;
    return currentUserId != null && review.authorId == currentUserId;
  }

  List<_IndexedReview> _orderedReviews() {
    final indexed = widget.reviews
        .asMap()
        .entries
        .map((e) => _IndexedReview(originalIndex: e.key, review: e.value))
        .toList(growable: false);
    final mine = indexed
        .where((r) => _isOwnReview(r.review))
        .toList(growable: false);
    final others = indexed
        .where((r) => !_isOwnReview(r.review))
        .toList(growable: false);
    others.sort(_sortByNewestDate);
    return [...mine, ...others];
  }

  int _sortByNewestDate(_IndexedReview a, _IndexedReview b) {
    return _reviewDate(b.review).compareTo(_reviewDate(a.review));
  }

  DateTime _reviewDate(Review review) {
    final parsed = DateTime.tryParse(review.date);
    if (parsed == null) return DateTime.fromMillisecondsSinceEpoch(0);
    return parsed.toUtc();
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

class _IndexedReview {
  const _IndexedReview({required this.originalIndex, required this.review});

  final int originalIndex;
  final Review review;
}
