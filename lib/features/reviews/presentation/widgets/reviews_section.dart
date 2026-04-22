import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/features/auth/data/users_api.dart'
    show currentLoggedInUser;
import 'package:agendat/core/api/reviews_api.dart';
import 'package:agendat/core/dto/review_dto.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/profile/data/profile_api.dart'
    show fetchUserSessions;
import 'package:agendat/features/reviews/presentation/widgets/add_review_form.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';
import 'package:agendat/features/reviews/presentation/widgets/reviews_list.dart';

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

  final ReviewsApi _reviewsApi = ReviewsApi();

  bool _isExpanded = false;
  bool _isFormOpen = false;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Índex dins [_reviews] de la valoració que s'està editant.
  /// `null` si el formulari està obert per afegir-ne una de nova
  /// o si no hi ha formulari obert.
  int? _editingIndex;

  /// Ids de valoracions amb una petició de like/unlike en curs.
  final Set<int> _busyLikeIds = <int>{};

  List<Review> _reviews = [];

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  // ─────────────────────────── Carrega dades ───────────────────────────

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dtos = await _reviewsApi.fetchReviewsByEventCode(widget.eventCode);
      if (!mounted) return;
      final reviews = dtos.map((dto) => dto.toModel()).toList(growable: true);
      _pinOwnReviewFirst(reviews);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('ReviewsSection._fetchReviews failed: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      setState(() {
        _error = 'No s\'han pogut carregar les valoracions.';
        _isLoading = false;
      });
    }
  }

  /// Si l'usuari té una valoració dins [reviews] i no està ja al principi,
  /// la mou a la posició 0. Muta la llista rebuda.
  void _pinOwnReviewFirst(List<Review> reviews) {
    final username = _currentUsername;
    if (username == null) return;
    final idx = reviews.indexWhere((r) => r.author == username);
    if (idx > 0) {
      final mine = reviews.removeAt(idx);
      reviews.insert(0, mine);
    }
  }

  /// Mitjana d'una puntuació concreta per a totes les valoracions carregades.
  /// Retorna 0 si encara no n'hi ha cap.
  double _averageOf(int Function(Review r) selector) {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + selector(r));
    return (sum / _reviews.length).clamp(0, 5);
  }

  /// Username de l'usuari que ha iniciat sessió, o `null` si no n'hi ha cap.
  String? get _currentUsername => currentLoggedInUser?['username'] as String?;

  /// Índex dins [_reviews] de la valoració de l'usuari loggejat,
  /// o `null` si encara no n'ha fet cap.
  int? get _userReviewIndex {
    final username = _currentUsername;
    if (username == null) return null;
    final idx = _reviews.indexWhere((r) => r.author == username);
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
    // Abans d'obrir el formulari confirmem que l'usuari té alguna sessió
    // ja finalitzada per aquest esdeveniment (condició que imposa el
    // backend). Si la comprovació falla per xarxa deixem continuar: el
    // POST ja es rebutjarà i ho capturarem com a
    // `ReviewAttendanceRequiredException`.
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

  /// Comprova si l'usuari té almenys una sessió ja finalitzada per
  /// l'esdeveniment actual. És la condició que el backend exigeix per
  /// poder deixar una valoració.
  ///
  /// Si la petició falla (xarxa, etc.) retornem `true` per no bloquejar
  /// l'usuari: en cas que no hi hagi assistit, el POST posterior ho
  /// acabarà detectant igualment.
  Future<bool> _hasConfirmedAttendance() async {
    final username = _currentUsername;
    if (username == null) return false;
    try {
      final sessions = await fetchUserSessions(username: username);
      final now = DateTime.now();
      return sessions.any(
        (s) =>
            s.event == widget.eventCode &&
            s.endTime != null &&
            s.endTime!.isBefore(now),
      );
    } catch (e, stack) {
      debugPrint('ReviewsSection._hasConfirmedAttendance failed: $e');
      debugPrintStack(stackTrace: stack);
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

    final dto = ReviewDto(
      id: existing?.id,
      eventCode: widget.eventCode,
      general: generalRating,
      preu: preuRating,
      ambient: ambientRating,
      accessibilitat: accessibilitatRating,
      comment: comment.trim().isEmpty ? null : comment.trim(),
    );

    setState(() => _isSubmitting = true);
    try {
      final ReviewDto saved;
      if (existing != null) {
        saved = await _reviewsApi.updateReview(widget.eventCode, dto);
      } else {
        saved = await _reviewsApi.createReview(widget.eventCode, dto);
      }
      if (!mounted) return;
      // Forcem `author` a l'username actual (quan el tenim) perquè la UI
      // reconegui la valoració com a pròpia —botons d'editar/eliminar—
      // sense dependre del format exacte de l'autor que torni el backend.
      final username = _currentUsername;
      final savedReview = (username != null && username.isNotEmpty)
          ? saved.toModel().copyWith(author: username)
          : saved.toModel();
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
        existing != null
            ? 'Valoració actualitzada correctament.'
            : 'Moltes gràcies per la teva valoració, quan l\'haguem validat la publicarem.',
      );
    } on ReviewAttendanceRequiredException catch (e) {
      debugPrint('ReviewsSection._submitReview attendance required: $e');
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showAttendanceRequiredDialog();
    } on ReviewAlreadyExistsException catch (e) {
      debugPrint('ReviewsSection._submitReview duplicate: $e');
      if (!mounted) return;
      setState(() {
        _closeForm();
        _isSubmitting = false;
      });
      _showAlreadyReviewedDialog();
      // Recarreguem per poder ensenyar la valoració existent i permetre
      // editar-la enlloc d'intentar crear-ne una altra.
      _fetchReviews();
    } catch (e, stack) {
      debugPrint('ReviewsSection._submitReview failed: $e');
      debugPrintStack(stackTrace: stack);
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
      await _reviewsApi.deleteReview(widget.eventCode, reviewId);
      if (!mounted) return;
      setState(() {
        _reviews.removeWhere((r) => r.id == reviewId);
        if (_editingIndex != null) _closeForm();
      });
      _showSnack('Valoració eliminada.');
    } catch (e, stack) {
      debugPrint('ReviewsSection._deleteReview failed: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      _showSnack('No s\'ha pogut eliminar la valoració.');
    }
  }

  /// Alterna el like d'una valoració amb actualització optimista.
  Future<void> _toggleLike(Review review) async {
    final reviewId = review.id;
    if (reviewId == null) return;
    if (_currentUsername == null) {
      _showSnack('Cal iniciar sessió per fer like.');
      return;
    }
    if (_busyLikeIds.contains(reviewId)) return;

    final idx = _reviews.indexWhere((r) => r.id == reviewId);
    if (idx < 0) return;

    final original = _reviews[idx];
    final optimistic = original.copyWith(
      isLikedByMe: !original.isLikedByMe,
      likesCount: original.isLikedByMe
          ? math.max(0, original.likesCount - 1)
          : original.likesCount + 1,
    );

    setState(() {
      _reviews[idx] = optimistic;
      _busyLikeIds.add(reviewId);
    });

    try {
      if (original.isLikedByMe) {
        await _reviewsApi.unlikeReview(widget.eventCode, reviewId);
      } else {
        await _reviewsApi.likeReview(widget.eventCode, reviewId);
      }
      if (!mounted) return;
      setState(() => _busyLikeIds.remove(reviewId));
    } catch (e, stack) {
      debugPrint('ReviewsSection._toggleLike failed: $e');
      debugPrintStack(stackTrace: stack);
      if (!mounted) return;
      setState(() {
        final current = _reviews.indexWhere((r) => r.id == reviewId);
        if (current >= 0) _reviews[current] = original;
        _busyLikeIds.remove(reviewId);
      });
      _showSnack('No s\'ha pogut actualitzar el like.');
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
      if (!_isFormOpen) _buildMainActionButton(),
      if (_isFormOpen) _buildReviewForm(),
      ReviewsList(
        reviews: _reviews,
        currentUsername: _currentUsername,
        // Mentre hi ha un formulari obert no deixem editar/eliminar una altra.
        onEditReview: _isFormOpen ? null : _openEditForm,
        onDeleteReview: _isFormOpen ? null : _deleteReview,
        onToggleLike: _currentUsername == null ? null : _toggleLike,
        busyLikeIds: _busyLikeIds,
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
                const Expanded(
                  child: Text(
                    'VALORACIONS',
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
    final general = _averageOf((r) => r.general).round();
    final preu = _averageOf((r) => r.preu).round();
    final ambient = _averageOf((r) => r.ambient).round();
    final access = _averageOf((r) => r.accessibilitat).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReviewRatingRow(
          label: 'General ($general)',
          rating: general,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: 20,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Preu ($preu)',
          rating: preu,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: 20,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Ambient ($ambient)',
          rating: ambient,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: 20,
          bottomSpacing: 6,
        ),
        ReviewRatingRow(
          label: 'Accessibilitat ($access)',
          rating: access,
          labelWidth: 130,
          labelStyle: labelStyle,
          starSize: 20,
          bottomSpacing: 0,
        ),
      ],
    );
  }

  /// Botó principal de la secció desplegada:
  ///   - "Afegir valoració" si l'usuari encara no n'ha fet cap.
  ///   - "Editar valoració" si ja en té una (obre el formulari pre-omplert).
  Widget _buildMainActionButton() {
    final userIdx = _userReviewIndex;
    final isEditing = userIdx != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _currentUsername == null
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
