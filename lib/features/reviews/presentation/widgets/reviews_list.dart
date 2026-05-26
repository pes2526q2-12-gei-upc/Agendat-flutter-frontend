import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_card.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_sort_criterion.dart';

/// Llista de valoracions d'un esdeveniment.
///
/// Comença mostrant [initialLimit] valoracions i ofereix un botó
/// "Mostrar més" per carregar-ne més de [initialLimit] en [initialLimit].
/// Un cop l'usuari n'ha desplegat alguna, apareix també "Mostrar menys"
/// per tornar a l'estat inicial.
///
/// Per defecte s'ordenen per reputació (més a menys). L'usuari pot
/// canviar el criteri i alternar ascendent/descendent.
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
    this.onTranslateReview,
    this.busyLikeIds = const {},
    this.translatingReviewIds = const {},
    this.translatedCommentsByReviewId = const {},
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

  /// Es crida quan l'usuari demana traduir una valoració a un idioma.
  final void Function(Review review, String language)? onTranslateReview;

  /// Conjunt d'`id` de valoracions amb una petició de like/unlike en curs
  /// per deshabilitar el botó i evitar doble click.
  final Set<int> busyLikeIds;
  final Set<int> translatingReviewIds;
  final Map<int, String> translatedCommentsByReviewId;

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  late int _visibleCount = widget.initialLimit;
  ReviewSortCriterion _sortCriterion = ReviewSortCriterion.reputation;
  bool _sortDescending = true;
  final Map<String, double> _reputationByAuthorId = <String, double>{};
  bool _isLoadingReputations = false;

  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);

  final ProfileQuery _profileQuery = ProfileQuery.instance;

  @override
  void initState() {
    super.initState();
    if (_sortCriterion == ReviewSortCriterion.reputation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureReputationsLoaded();
      });
    }
  }

  @override
  void didUpdateWidget(ReviewsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sortCriterion == ReviewSortCriterion.reputation &&
        widget.reviews != oldWidget.reviews) {
      _ensureReputationsLoaded();
    }
  }

  void _showMore() => setState(() => _visibleCount += widget.initialLimit);

  void _showLess() => setState(() => _visibleCount = widget.initialLimit);

  void _onSortChanged(ReviewSortCriterion? value) {
    if (value == null || value == _sortCriterion) return;
    setState(() {
      _sortCriterion = value;
      _sortDescending = true;
      _visibleCount = widget.initialLimit;
    });
    if (value == ReviewSortCriterion.reputation) {
      _ensureReputationsLoaded();
    }
  }

  void _toggleSortDirection() {
    setState(() {
      _sortDescending = !_sortDescending;
      _visibleCount = widget.initialLimit;
    });
  }

  Future<void> _ensureReputationsLoaded() async {
    if (_isLoadingReputations) return;

    final missingAuthorIds = widget.reviews
        .map((review) => review.authorId?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .where((id) => !_reputationByAuthorId.containsKey(id))
        .toSet();

    if (missingAuthorIds.isEmpty) return;

    setState(() => _isLoadingReputations = true);

    final resolved = await Future.wait(
      missingAuthorIds.map(_fetchAuthorReputation),
    );

    if (!mounted) return;

    setState(() {
      for (final entry in resolved) {
        _reputationByAuthorId[entry.key] = entry.value;
      }
      _isLoadingReputations = false;
    });
  }

  Future<MapEntry<String, double>> _fetchAuthorReputation(
    String authorId,
  ) async {
    final userId = int.tryParse(authorId);
    if (userId == null) return MapEntry(authorId, 0);

    try {
      final reputation = await _profileQuery.getUserReputation(userId);
      if (reputation != null) {
        return MapEntry(authorId, reputation);
      }
    } catch (_) {}

    return MapEntry(authorId, 0);
  }

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
        _buildSortSelector(),
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
            onLanguageChanged: widget.onTranslateReview == null
                ? null
                : (language) => widget.onTranslateReview!(
                    visibleReviews[i].review,
                    language,
                  ),
            isLikeBusy:
                visibleReviews[i].review.id != null &&
                widget.busyLikeIds.contains(visibleReviews[i].review.id),
            isTranslating:
                visibleReviews[i].review.id != null &&
                widget.translatingReviewIds.contains(
                  visibleReviews[i].review.id,
                ),
            translatedComment: visibleReviews[i].review.id == null
                ? null
                : widget.translatedCommentsByReviewId[visibleReviews[i]
                      .review
                      .id!],
          ),
        if (hasMore) _buildTextButton('Mostrar més', _showMore),
        if (canCollapse) _buildTextButton('Mostrar menys', _showLess),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSortSelector() {
    const selectorHeight = 48.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Ordenar per:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: selectorHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ReviewSortCriterion>(
                      value: _sortCriterion,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      items: ReviewSortCriterion.values
                          .map(
                            (criterion) => DropdownMenuItem(
                              value: criterion,
                              child: Text(
                                criterion.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _onSortChanged,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: _sortCriterion.directionLabel(descending: _sortDescending),
            child: SizedBox(
              height: selectorHeight,
              child: OutlinedButton(
                onPressed: _toggleSortDirection,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _brandRed,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(selectorHeight, selectorHeight),
                ),
                child: Icon(
                  _sortDescending
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  size: 20,
                ),
              ),
            ),
          ),
          if (_sortCriterion == ReviewSortCriterion.reputation &&
              _isLoadingReputations) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _brandRed,
              ),
            ),
          ],
        ],
      ),
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
    others.sort(_compareReviews);
    return [...mine, ...others];
  }

  int _compareReviews(_IndexedReview a, _IndexedReview b) {
    final primary = switch (_sortCriterion) {
      ReviewSortCriterion.date => _reviewDate(
        b.review,
      ).compareTo(_reviewDate(a.review)),
      ReviewSortCriterion.general => b.review.general.compareTo(
        a.review.general,
      ),
      ReviewSortCriterion.price => b.review.preu.compareTo(a.review.preu),
      ReviewSortCriterion.atmosphere => b.review.ambient.compareTo(
        a.review.ambient,
      ),
      ReviewSortCriterion.accessibility => b.review.accessibilitat.compareTo(
        a.review.accessibilitat,
      ),
      ReviewSortCriterion.reputation => _authorReputation(
        b.review,
      ).compareTo(_authorReputation(a.review)),
      ReviewSortCriterion.likes => b.review.likesCount.compareTo(
        a.review.likesCount,
      ),
    };
    final directed = _sortDescending ? primary : -primary;
    if (directed != 0) return directed;
    final tieBreak = _reviewDate(b.review).compareTo(_reviewDate(a.review));
    return _sortDescending ? tieBreak : -tieBreak;
  }

  double _authorReputation(Review review) {
    final authorId = review.authorId?.trim();
    if (authorId == null || authorId.isEmpty) return 0;
    return _reputationByAuthorId[authorId] ?? 0;
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
