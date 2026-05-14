import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/features/auth/data/users_api.dart'
    show currentLoggedInUser;
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/query/reviews_query.dart';
import 'package:agendat/features/reviews/presentation/helpers/reviews_section_helpers.dart';
import 'package:agendat/features/reviews/presentation/widgets/add_review_form.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_average_summary.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_collapsible_header.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_list.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_load_error_banner.dart';

/// Secció "VALORACIONS" de la vista de detall d'un esdeveniment.
///
/// Comportament:
///   - Per defecte es mostra col·lapsada, amb el títol i la nota mitjana
///     (arrodonida) en forma d'estrelles.
///   - En desplegar-la, apareix un botó "Afegir valoració" (o "Editar
///     valoració" si l'usuari ja n'hi ha deixat una) i la llista paginada
///     amb les ressenyes de la resta d'usuaris.
///   - Un usuari només pot tenir una valoració per esdeveniment; clicant
///     "Editar" (o el llapis a la seva pròpia targeta) s'obre el mateix
///     formulari pre-omplert.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.eventCode});

  /// Codi de l'esdeveniment del qual mostrem les valoracions.
  final String eventCode;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);

  final ReviewsQuery _reviewsQuery = ReviewsQuery.instance;

  bool _isExpanded = false;
  bool _isFormOpen = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Índex dins [_reviews] de la valoració que s'està editant.
  int? _editingIndex;

  final Set<int> _busyLikeIds = <int>{};
  final Set<int> _translatingReviewIds = <int>{};
  final Map<int, String> _translatedCommentsByReviewId = <int, String>{};
  final Map<int, String> _currentCommentLanguageByReviewId = <int, String>{};

  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final reviewsFromServer = await _reviewsQuery.fetchReviewsByEventCode(
        widget.eventCode,
      );
      if (!mounted) return;
      final reviews = reviewsFromServer
          .map(
            (review) => _isOwnReview(review)
                ? mergeSavedReviewWithViewerProfile(
                    saved: review,
                    viewerUserId: _currentUserId,
                    viewerUsername: _currentUsername,
                    viewerAvatarUrl: _currentUserAvatarUrl,
                  )
                : review,
          )
          .toList(growable: true);
      if (silent) {
        mergePendingOwnReviewsWithoutServerId(
          previousList: _reviews,
          serverMerged: reviews,
          isOwnReview: _isOwnReview,
          sameOwnByRatings: (a, b) =>
              sameOwnReviewByRatings(a, b, _isOwnReview),
        );
      }
      pinOwnReviewFirst(reviews, _isOwnReview);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (silent) return;
      setState(() {
        _error = 'No s\'han pogut carregar les valoracions.';
        _isLoading = false;
      });
    }
  }

  String? get _currentUsername {
    final raw = currentLoggedInUser?['username'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  String? get _currentUserId {
    final raw = currentLoggedInUser?['id'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  String? get _currentUserAvatarUrl {
    final raw = currentLoggedInUser?['profile_image'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  bool _isOwnReview(Review review) {
    final currentUserId = _currentUserId;
    return currentUserId != null && review.authorId == currentUserId;
  }

  bool get _isLoggedIn => _currentUserId != null;

  int? get _userReviewIndex {
    final idx = _reviews.indexWhere(_isOwnReview);
    return idx >= 0 ? idx : null;
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) _closeForm();
    });
  }

  Future<void> _openAddForm() async {
    final pre = await _precheckAttendanceForNewReview();
    if (!mounted) return;
    switch (pre) {
      case _AttendancePrecheck.proceed:
        setState(() {
          _isFormOpen = true;
          _editingIndex = null;
        });
        break;
      case _AttendancePrecheck.needAttendanceDialog:
        _showAttendanceRequiredDialog();
        break;
      case _AttendancePrecheck.checkFailed:
        _showSnack(
          'No s\'ha pogut comprovar l\'assistència. Torna-ho a intentar.',
        );
        break;
    }
  }

  /// Comprova assistència abans d'obrir el formulari de valoració nova.
  /// En error de xarxa o API no s'assumeix assistència: es demana reintent.
  Future<_AttendancePrecheck> _precheckAttendanceForNewReview() async {
    final username = _currentUsername;
    if (username == null) return _AttendancePrecheck.needAttendanceDialog;
    try {
      final attended = await _reviewsQuery.hasConfirmedAttendance(
        username: username,
        eventCode: widget.eventCode,
      );
      return attended
          ? _AttendancePrecheck.proceed
          : _AttendancePrecheck.needAttendanceDialog;
    } catch (_) {
      return _AttendancePrecheck.checkFailed;
    }
  }

  void _showAttendanceRequiredDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No pots valorar aquest esdeveniment'),
        content: const Text(
          'Només pots valorar esdeveniments als quals has assistit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: _brandRed),
            child: const Text('Entesos'),
          ),
        ],
      ),
    );
  }

  void _showAlreadyReviewedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ja has valorat aquest esdeveniment'),
        content: const Text(
          'Ja tens una valoració per aquest esdeveniment. Si la vols '
          'canviar, fes servir el botó d\'editar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(foregroundColor: _brandRed),
            child: const Text('Entesos'),
          ),
        ],
      ),
    );
  }

  void _openEditForm(int index) {
    setState(() {
      _isFormOpen = true;
      _editingIndex = index;
    });
  }

  void _closeForm() {
    _isFormOpen = false;
    _editingIndex = null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitReview({
    required int generalRating,
    required int preuRating,
    required int ambientRating,
    required int accessibilitatRating,
    required String comment,
    required List<XFile> media,
  }) async {
    if (_isSubmitting) return;

    final editingIndex = _editingIndex;
    final existing = editingIndex != null ? _reviews[editingIndex] : null;

    final submittedComment = comment.trim().isEmpty ? null : comment.trim();

    setState(() => _isSubmitting = true);
    try {
      final SaveReviewResult result;
      if (existing?.id != null) {
        result = await _reviewsQuery.updateReview(
          eventCode: widget.eventCode,
          reviewId: existing!.id!,
          general: generalRating,
          preu: preuRating,
          ambient: ambientRating,
          accessibilitat: accessibilitatRating,
          comment: submittedComment,
        );
      } else {
        result = await _reviewsQuery.createReview(
          eventCode: widget.eventCode,
          general: generalRating,
          preu: preuRating,
          ambient: ambientRating,
          accessibilitat: accessibilitatRating,
          comment: submittedComment,
        );
      }
      if (!mounted) return;
      final hasSubmittedComment = submittedComment?.isNotEmpty == true;
      final commentNeedsModeration =
          result.acceptedForModeration && hasSubmittedComment;
      final savedReview = mergeSavedReviewWithViewerProfile(
        saved: result.review,
        viewerUserId: _currentUserId,
        viewerUsername: _currentUsername,
        viewerAvatarUrl: _currentUserAvatarUrl,
        existing: existing,
        submittedComment: submittedComment,
        hideSubmittedComment: commentNeedsModeration,
      );
      setState(() {
        if (editingIndex != null) {
          _reviews[editingIndex] = savedReview;
        } else {
          _reviews.insert(0, savedReview);
        }
        _closeForm();
        _isSubmitting = false;
      });
      _showSnack(
        commentNeedsModeration
            ? 'Moltes gràcies per la teva valoració, quan l\'haguem validat la publicarem.'
            : (existing != null
                  ? 'Valoració actualitzada correctament.'
                  : 'Valoració publicada correctament.'),
      );
      // ignore: unawaited_futures
      _fetchReviews(silent: true);
    } on ReviewAttendanceRequiredException catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showAttendanceRequiredDialog();
    } on ReviewAlreadyExistsException catch (_) {
      if (!mounted) return;
      setState(() {
        _closeForm();
        _isSubmitting = false;
      });
      _showAlreadyReviewedDialog();
      _fetchReviews();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnack(
        existing != null
            ? 'No s\'ha pogut actualitzar la valoració.'
            : 'No s\'ha pogut publicar la valoració.',
      );
    }
  }

  Future<void> _deleteReview(Review review) async {
    final reviewId = review.id;
    if (reviewId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar valoració'),
        content: const Text(
          'Segur que vols eliminar la teva valoració? Aquesta acció no es '
          'pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel·lar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _brandRed),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _reviewsQuery.deleteReview(widget.eventCode, reviewId);
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((r) => r.id == reviewId);
        if (_editingIndex != null) _closeForm();
      });
      _showSnack('Valoració eliminada.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('No s\'ha pogut eliminar la valoració.');
    }
  }

  Future<void> _toggleLike(Review review) async {
    final reviewId = review.id;
    if (reviewId == null) return;
    if (!_isLoggedIn) {
      _showSnack('Cal iniciar sessió per fer like.');
      return;
    }
    if (_busyLikeIds.contains(reviewId)) return;

    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx < 0) return;

    final original = _reviews[idx];
    final wasLiked = original.isLikedByMe;

    final optimistic = original.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: wasLiked
          ? (original.likesCount > 0 ? original.likesCount - 1 : 0)
          : original.likesCount + 1,
    );

    setState(() {
      _reviews[idx] = optimistic;
      _busyLikeIds.add(reviewId);
    });

    try {
      if (wasLiked) {
        await _reviewsQuery.unlikeReview(widget.eventCode, reviewId);
      } else {
        await _reviewsQuery.likeReview(widget.eventCode, reviewId);
      }
      if (!mounted) return;
      setState(() => _busyLikeIds.remove(reviewId));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final current = _reviews.indexWhere((r) => r.id == reviewId);
        if (current >= 0) _reviews[current] = original;
        _busyLikeIds.remove(reviewId);
      });
      _showSnack('No s\'ha pogut actualitzar el like.');
    }
  }

  Future<void> _translateReview(Review review, String language) async {
    final reviewId = review.id;
    if (reviewId == null) return;
    if (_translatingReviewIds.contains(reviewId)) return;
    final currentComment = (review.comment ?? '').trim();
    if (currentComment.isEmpty) {
      _showSnack('Aquesta valoració no té comentari per traduir.');
      return;
    }
    final selectedLanguage = language.trim().toUpperCase();
    final knownCurrentLanguage = _currentCommentLanguageByReviewId[reviewId]
        ?.trim()
        .toUpperCase();
    if (knownCurrentLanguage != null &&
        knownCurrentLanguage == selectedLanguage) {
      _showSnack('La valoració ja està en aquest idioma.');
      return;
    }

    setState(() {
      _translatingReviewIds.add(reviewId);
      _translatedCommentsByReviewId.remove(reviewId);
    });

    try {
      final result = await _reviewsQuery.translateReview(
        widget.eventCode,
        reviewId,
        language,
      );
      if (!mounted) return;
      final responseTargetLanguage = (result?.targetLanguage ?? '')
          .trim()
          .toUpperCase();
      final translatedComment = (result?.translatedComment ?? '').trim();
      final targetLanguageMismatch =
          responseTargetLanguage.isNotEmpty &&
          responseTargetLanguage != selectedLanguage;
      final backendFallbackDetected =
          result == null || translatedComment.isEmpty || targetLanguageMismatch;

      setState(() {
        if (!backendFallbackDetected) {
          _translatedCommentsByReviewId[reviewId] = translatedComment;
          _currentCommentLanguageByReviewId[reviewId] =
              responseTargetLanguage.isEmpty
              ? selectedLanguage
              : responseTargetLanguage;
        }
        _translatingReviewIds.remove(reviewId);
      });
      if (backendFallbackDetected) {
        _showSnack('Traducció no disponible temporalment.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _translatingReviewIds.remove(reviewId));
      _showSnack('No s\'ha pogut traduir la valoració.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewsCollapsibleHeader(
          brandRed: _brandRed,
          reviewCount: _reviews.length,
          isExpanded: _isExpanded,
          onToggle: _toggleExpanded,
          summary: ReviewsAverageSummary(
            reviews: _reviews,
            isLoadingWhenListEmpty: _isLoading,
          ),
        ),
        if (_isExpanded) ..._buildExpandedBody(),
      ],
    );
  }

  List<Widget> _buildExpandedBody() {
    if (_isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator(color: _brandRed)),
        ),
      ];
    }
    return [
      if (_error != null)
        ReviewsLoadErrorBanner(
          brandRed: _brandRed,
          message: _error ?? 'Hi ha hagut un error carregant les valoracions.',
          onRetry: _fetchReviews,
        ),
      if (!_isFormOpen) _buildMainActionButton(),
      if (_isFormOpen) _buildReviewForm(),
      ReviewsList(
        reviews: _reviews,
        currentUserId: _currentUserId,
        onEditReview: _isFormOpen ? null : _openEditForm,
        onDeleteReview: _isFormOpen ? null : _deleteReview,
        onToggleLike: _isLoggedIn ? _toggleLike : null,
        onTranslateReview: _translateReview,
        busyLikeIds: _busyLikeIds,
        translatingReviewIds: _translatingReviewIds,
        translatedCommentsByReviewId: _translatedCommentsByReviewId,
      ),
    ];
  }

  Widget _buildMainActionButton() {
    final userIdx = _userReviewIndex;
    final isEditing = userIdx != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: !_isLoggedIn
              ? null
              : (isEditing
                    ? () => _openEditForm(userIdx)
                    : () => _openAddForm()),
          icon: Icon(
            isEditing ? Icons.edit_rounded : Icons.add_rounded,
            size: 20,
            color: _brandRed,
          ),
          label: Text(
            isEditing ? 'Editar valoració' : 'Afegir valoració',
            style: const TextStyle(
              color: _brandRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _brandRed),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    final editing = _editingIndex != null ? _reviews[_editingIndex!] : null;
    return AddReviewForm(
      key: ValueKey('review-form-${editing?.id ?? 'new'}'),
      isEditing: editing != null,
      initialGeneralRating: editing?.general ?? 0,
      initialPreuRating: editing?.preu ?? 0,
      initialAmbientRating: editing?.ambient ?? 0,
      initialAccessibilitatRating: editing?.accessibilitat ?? 0,
      initialComment: editing?.comment ?? '',
      onCancel: _isSubmitting ? () {} : () => setState(_closeForm),
      onSubmit: _submitReview,
    );
  }
}

enum _AttendancePrecheck { proceed, needAttendanceDialog, checkFailed }
