import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/features/auth/data/users_api.dart'
    show currentLoggedInUser;
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/query/reviews_query.dart';
import 'package:agendat/features/reviews/presentation/widgets/add_review_form.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_list.dart';

/// Secció "VALORACIONS" de la vista de detall d'un esdeveniment.
///
/// Comportament:
///   - Per defecte es mostra col·lapsada, amb el títol i la nota mitjana
///     (arrodonida) en forma d'estrelles.
///   - En desplegar-la, apareix un botó "Afegir valoració" si l'usuari encara
///     no n'ha deixat cap, i la llista paginada amb les ressenyes.
///   - Un usuari només pot tenir una valoració per esdeveniment; per editar-la
///     fa servir el llapis de la seva pròpia targeta.
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
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  bool _isExpanded = false;
  bool _isFormOpen = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Índex dins [_reviews] de la valoració que s'està editant.
  /// `null` si el formulari està obert per afegir-ne una de nova
  /// o si no hi ha formulari obert.
  int? _editingIndex;

  /// Evita que l'usuari premi el cor dues vegades mentre la petició és viva.
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

  // ─────────────────────────── Carrega dades ───────────────────────────

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
                ? _withCurrentUserDefaults(review)
                : review,
          )
          .toList(growable: true);
      if (silent) {
        _keepLocalPendingReview(reviews);
      }
      _pinOwnReviewFirst(reviews);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      // En mode silenciós no mostrem error: només era un refresc de fons.
      if (silent) return;
      setState(() {
        _error = 'No s\'han pogut carregar les valoracions.';
        _isLoading = false;
      });
    }
  }

  /// Si l'usuari té una valoració dins [reviews] i no està ja al principi,
  /// la mou a la posició 0. Muta la llista rebuda.
  void _pinOwnReviewFirst(List<Review> reviews) {
    final idx = reviews.indexWhere(_isOwnReview);
    if (idx > 0) {
      final mine = reviews.removeAt(idx);
      reviews.insert(0, mine);
    }
  }

  /// Si el POST ha tornat 202, la review encara no té id i pot no sortir al GET.
  void _keepLocalPendingReview(List<Review> serverReviews) {
    final pending = _reviews.where((r) => _isOwnReview(r) && r.id == null);
    for (final review in pending) {
      final alreadyPublished = serverReviews.any(
        (serverReview) => _isSameReviewByRatings(serverReview, review),
      );
      if (!alreadyPublished) {
        serverReviews.insert(0, review);
      }
    }
  }

  bool _isSameReviewByRatings(Review a, Review b) {
    return _isOwnReview(a) &&
        _isOwnReview(b) &&
        a.general == b.general &&
        a.preu == b.preu &&
        a.ambient == b.ambient &&
        a.accessibilitat == b.accessibilitat;
  }

  /// Mitjana d'una puntuació concreta per a totes les valoracions carregades.
  /// Retorna 0 si encara no n'hi ha cap.
  double _averageOf(int Function(Review r) selector) {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + selector(r));
    return (sum / _reviews.length).clamp(0, 5);
  }

  /// Mostra fins a un decimal, sense ".0" si és un enter.
  String _formatAverageLabel(double value) {
    final roundedToOneDecimal = (value * 10).round() / 10;
    final oneDecimal = roundedToOneDecimal.toStringAsFixed(1);
    return oneDecimal.endsWith('.0')
        ? oneDecimal.substring(0, oneDecimal.length - 2)
        : oneDecimal;
  }

  /// Username de l'usuari loggejat.
  String? get _currentUsername {
    final raw = currentLoggedInUser?['username'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  /// Id de l'usuari loggejat. El passem a String per comparar fàcilment.
  String? get _currentUserId {
    final raw = currentLoggedInUser?['id'];
    if (raw == null) return null;
    final id = raw.toString().trim();
    return id.isEmpty ? null : id;
  }

  /// Foto de perfil de l'usuari loggejat.
  String? get _currentUserAvatarUrl {
    final raw = currentLoggedInUser?['profile_image'];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
    return null;
  }

  /// Una review és meva si coincideix el reviewer_id.
  bool _isOwnReview(Review review) {
    final currentUserId = _currentUserId;
    return currentUserId != null && review.authorId == currentUserId;
  }

  bool get _isLoggedIn => _currentUserId != null;

  /// Completa una review meva quan el backend torna una resposta parcial.
  Review _withCurrentUserDefaults(
    Review saved, {
    Review? existing,
    String? submittedComment,
    bool hideSubmittedComment = false,
  }) {
    final username = _currentUsername;
    String author;
    if (username != null && username.isNotEmpty) {
      author = username;
    } else if (saved.author.trim().isNotEmpty) {
      author = saved.author;
    } else {
      author = existing?.author ?? '';
    }

    final fromServerAvatar = saved.authorAvatarUrl?.trim();
    final hasServerAvatar =
        fromServerAvatar != null && fromServerAvatar.isNotEmpty;
    final avatarUrl = hasServerAvatar
        ? saved.authorAvatarUrl
        : (existing?.authorAvatarUrl ?? _currentUserAvatarUrl);

    String? comment = hideSubmittedComment ? null : saved.comment;
    if (!hideSubmittedComment && (comment == null || comment.trim().isEmpty)) {
      final fallbackComment = submittedComment?.trim();
      if (fallbackComment != null && fallbackComment.isNotEmpty) {
        comment = fallbackComment;
      } else if (existing?.comment != null &&
          existing!.comment!.trim().isNotEmpty) {
        comment = existing.comment;
      } else {
        comment = null;
      }
    }

    final imageUrls = saved.imageUrls.isNotEmpty
        ? saved.imageUrls
        : (existing?.imageUrls ?? const <String>[]);

    final date = saved.date.trim().isNotEmpty
        ? saved.date
        : (existing != null && existing.date.trim().isNotEmpty
              ? existing.date
              : DateTime.now().toUtc().toIso8601String());

    return Review(
      id: saved.id ?? existing?.id,
      authorId: saved.authorId ?? existing?.authorId ?? _currentUserId,
      author: author,
      authorAvatarUrl: avatarUrl,
      general: saved.general,
      preu: saved.preu,
      ambient: saved.ambient,
      accessibilitat: saved.accessibilitat,
      comment: comment,
      imageUrls: imageUrls,
      date: date,
      likesCount: saved.likesCount,
      isLikedByMe: saved.isLikedByMe,
    );
  }

  /// Índex dins [_reviews] de la valoració de l'usuari loggejat,
  /// o `null` si encara no n'ha fet cap.
  int? get _userReviewIndex {
    final idx = _reviews.indexWhere(_isOwnReview);
    return idx >= 0 ? idx : null;
  }

  // ───────────────────────────── Situacions que podem tenir ───────────────────────────────

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      // Si es tanca la secció, també amaguem el formulari.
      if (!_isExpanded) _closeForm();
    });
  }

  Future<void> _openAddForm() async {
    // Només pot valorar qui té una sessió finalitzada d'aquest esdeveniment.
    final attended = await _hasConfirmedAttendance();
    if (!mounted) return;
    if (!attended) {
      _showAttendanceRequiredDialog();
      return;
    }
    setState(() {
      _isFormOpen = true;
      _editingIndex = null;
    });
  }

  /// Retorna true si l'usuari ha assistit a alguna sessió ja acabada.
  Future<bool> _hasConfirmedAttendance() async {
    final username = _currentUsername;
    if (username == null) return false;
    try {
      return _reviewsQuery.hasConfirmedAttendance(eventCode: widget.eventCode);
    } catch (_) {
      return true;
    }
  }

  /// Diàleg que avisa que l'usuari no pot valorar un esdeveniment perquè
  /// no hi ha assistit.
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

  /// Diàleg que avisa que l'usuari ja té una valoració d'aquest
  /// esdeveniment i que ha d'editar-la en comptes de crear-ne una nova.
  void _showAlreadyReviewedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ja has valorat aquest esdeveniment'),
        content: const Text(
          'Ja tens una valoració per aquest esdeveniment. Si la vols '
          'canviar, fes servir el llapis de la teva valoració.',
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
      debugPrint('openEditForm: $index');
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

  /// Es crida quan l'usuari prem "Afegir"/"Desar" al formulari.
  /// Envia la petició al servidor (POST/PATCH) i actualitza la llista
  /// amb la resposta.
  ///
  /// TODO(backend): quan hi hagi endpoint de pujada de fitxers, convertir
  /// [media] a URLs abans d'enviar-les al DTO.
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
      // Algunes respostes del backend no inclouen autor, foto o comentari.
      final savedReview = _withCurrentUserDefaults(
        result.review,
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
      final currentUserId = currentLoggedInUser?['id'];
      if (currentUserId is int) {
        _profileQuery.invalidateUser(currentUserId);
      }
      // Refresc silenciós per sincronitzar id real, likes i data del backend.
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
      // Recarreguem per ensenyar la valoració existent.
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

  /// Demana confirmació i elimina una valoració pròpia al servidor.
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

  /// Alterna el like d'una valoració amb actualització optimista.
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _translatingReviewIds.remove(reviewId));
      _showSnack('No s\'ha pogut traduir la valoració.');
    }
  }

  // ───────────────────────────── UI ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleHeader(),
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
      if (_error != null) _buildErrorBanner(),
      if (!_isFormOpen && _userReviewIndex == null) _buildMainActionButton(),
      if (_isFormOpen) _buildReviewForm(),
      ReviewsList(
        reviews: _reviews,
        currentUserId: _currentUserId,
        // Mentre hi ha un formulari obert no deixem editar/eliminar una altra.
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

  /// Banner inline que avisa d'un error de càrrega sense bloquejar la resta
  /// de la secció (l'usuari continua podent afegir valoracions).
  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'Hi ha hagut un error carregant les valoracions.',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: _fetchReviews,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Tornar a intentar',
              style: TextStyle(color: _brandRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Capçalera que sempre es veu: títol "VALORACIONS", mitjana d'estrelles
  /// i fletxa que indica si la secció està desplegada o no.
  Widget _buildCollapsibleHeader() {
    return InkWell(
      onTap: _toggleExpanded,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VALORACIONS (${_reviews.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _brandRed,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: _brandRed,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildAverageSummary(),
          ],
        ),
      ),
    );
  }

  /// Text "Valoració mitjana: ★★★★" o bé un missatge si encara no n'hi ha.
  Widget _buildAverageSummary() {
    if (_isLoading && _reviews.isEmpty) {
      return const Text(
        'Carregant valoracions...',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }
    if (_reviews.isEmpty) {
      return const Text(
        'Encara no hi ha valoracions.',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }
    const labelStyle = TextStyle(
      fontSize: 14,
      color: Colors.black87,
      fontWeight: FontWeight.w500,
    );
    final generalAvg = _averageOf((r) => r.general);
    final preuAvg = _averageOf((r) => r.preu);
    final ambientAvg = _averageOf((r) => r.ambient);
    final accessAvg = _averageOf((r) => r.accessibilitat);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewRatingRow(
          label: 'General (${_formatAverageLabel(generalAvg)})',
          rating: generalAvg,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: ReviewRatingRow.summaryGeneralStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Preu (${_formatAverageLabel(preuAvg)})',
          rating: preuAvg,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: ReviewRatingRow.summaryOtherCategoriesStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Ambient (${_formatAverageLabel(ambientAvg)})',
          rating: ambientAvg,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: ReviewRatingRow.summaryOtherCategoriesStarSize,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Accessibilitat (${_formatAverageLabel(accessAvg)})',
          rating: accessAvg,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: ReviewRatingRow.summaryOtherCategoriesStarSize,
          bottomSpacing: 0,
        ),
      ],
    );
  }

  /// Botó "Afegir valoració" (només si l'usuari encara no n'ha deixat cap).
  Widget _buildMainActionButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: !_isLoggedIn ? null : _openAddForm,
          icon: const Icon(Icons.add_rounded, size: 20, color: _brandRed),
          label: const Text(
            'Afegir valoració',
            style: TextStyle(color: _brandRed, fontWeight: FontWeight.w600),
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

  /// Formulari per afegir una valoració nova o editar-ne una d'existent.
  /// El `key` diferent per a cada mode força Flutter a recrear l'estat
  /// intern del formulari (i així no es barregen els valors inicials).
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
