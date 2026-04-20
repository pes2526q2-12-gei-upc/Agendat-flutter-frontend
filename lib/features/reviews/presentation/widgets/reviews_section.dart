import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/core/widgets/rating_stars.dart';
import 'package:agendat/features/auth/data/users_api.dart'
    show currentLoggedInUser;
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/reviews/presentation/widgets/add_review_form.dart';
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
///
/// TODO(backend): substituir la llista mock [_reviews] per les valoracions
/// reals. Caldrà:
///   1. Afegir els mètodes `fetchReviewsByEventCode` i `createReview` a
///      `ReviewsApi` (o a `EventsApi`).
///   2. Carregar-les dins un `FutureBuilder` usant [ReviewsSection.eventCode]
///      per identificar l'esdeveniment.
///   3. A [_submitReview] fer el POST/PATCH real i refrescar la llista
///      amb la resposta del servidor.
class ReviewsSection extends StatefulWidget {
  const ReviewsSection({super.key, required this.eventCode});

  /// Codi de l'esdeveniment del qual mostrem les valoracions.
  final String eventCode;

  @override
  State<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<ReviewsSection> {
  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);

  bool _isExpanded = false;
  bool _isFormOpen = false;

  /// Índex dins [_reviews] de la valoració que s'està editant.
  /// `null` si el formulari està obert per afegir-ne una de nova
  /// o si no hi ha formulari obert.
  int? _editingIndex;

  // TODO(backend): valoracions d'exemple per poder provar la UI (mitjana,
  // paginació, edició de la valoració pròpia...). S'ha d'eliminar quan la
  // llista vingui del backend.
  final List<Review> _reviews = [
    const Review(
      author: 'Usuari Demo',
      general: 4,
      preu: 3,
      ambient: 5,
      accessibilitat: 4,
      comment:
          'Una experiència molt recomanable! L\'ambient era immillorable i '
          'l\'organització va ser impecable. El preu em sembla una mica alt '
          'per el que s\'ofereix, però en general ha valgut molt la pena.',
      date: '15/04/2026',
    ),
    const Review(
      author: 'Marta',
      general: 5,
      preu: 4,
      ambient: 5,
      accessibilitat: 5,
      comment: 'M\'ha encantat! Repetiria sense dubtar-ho.',
      date: '10/04/2026',
    ),
    const Review(
      author: 'Jordi',
      general: 3,
      preu: 2,
      ambient: 4,
      accessibilitat: 3,
      comment:
          'Està bé, però esperava més pel preu que té. L\'ambient era correcte.',
      date: '05/04/2026',
    ),
    const Review(
      author: 'Laia',
      general: 4,
      preu: 4,
      ambient: 4,
      accessibilitat: 5,
      comment: 'Molt ben organitzat i accessible per tothom.',
      date: '02/04/2026',
    ),
    const Review(
      author: 'Pau',
      general: 5,
      preu: 5,
      ambient: 5,
      accessibilitat: 4,
      comment: 'Increïble! Una de les millors experiències de l\'any.',
      date: '28/03/2026',
    ),
  ];

  // ───────────────────────── Helpers de negoci ─────────────────────────

  /// Mitjana de la puntuació "General" sobre totes les valoracions.
  /// Retorna 0 si encara no n'hi ha cap.
  double get _averageGeneral {
    if (_reviews.isEmpty) return 0;
    final sum = _reviews.fold<int>(0, (acc, r) => acc + r.general);
    return sum / _reviews.length;
  }

  /// Mitjana arrodonida (0..5) per pintar-la com a estrelles.
  int get _averageStars => _averageGeneral.round().clamp(0, 5);

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

  /// Data d'avui formatada com a `dd/mm/aaaa`.
  String _todayFormatted() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.day)}/${two(now.month)}/${now.year}';
  }

  // ───────────────────────────── Accions ───────────────────────────────

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      // Si es tanca la secció, també amaguem el formulari.
      if (!_isExpanded) _closeForm();
    });
  }

  void _openAddForm() {
    setState(() {
      _isFormOpen = true;
      _editingIndex = null;
    });
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

  /// Es crida quan l'usuari prem "Afegir"/"Desar" al formulari.
  /// Si estem en mode edició, substitueix la valoració existent;
  /// si no, n'insereix una de nova al principi de la llista.
  ///
  /// TODO(backend): substituir la mutació local per una crida al servidor
  /// (POST a `/api/events/{eventCode}/reviews/` o PATCH a
  /// `/api/reviews/{id}/`) i refrescar `_reviews` amb la resposta.
  void _submitReview({
    required int generalRating,
    required int preuRating,
    required int ambientRating,
    required int accessibilitatRating,
    required String comment,
    required List<XFile> media,
  }) {
    setState(() {
      if (_editingIndex != null) {
        _reviews[_editingIndex!] = _reviews[_editingIndex!].copyWith(
          general: generalRating,
          preu: preuRating,
          ambient: ambientRating,
          accessibilitat: accessibilitatRating,
          comment: comment,
          date: _todayFormatted(),
        );
      } else {
        _reviews.insert(
          0,
          Review(
            // TODO(backend): l'autoria l'hauria d'assignar el servidor a
            // partir del token d'autenticació. Aquí només guardem el
            // username per poder detectar localment la valoració com a pròpia.
            author: _currentUsername ?? 'Tu',
            general: generalRating,
            preu: preuRating,
            ambient: ambientRating,
            accessibilitat: accessibilitatRating,
            comment: comment,
            // TODO(backend): substituir per les URLs retornades pel
            // servidor un cop pujats els fitxers de `media`.
            imageUrls: const [],
            date: _todayFormatted(),
          ),
        );
      }
      _closeForm();
    });
  }

  // ───────────────────────────── UI ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleHeader(),
        if (_isExpanded) ...[
          if (!_isFormOpen) _buildMainActionButton(),
          if (_isFormOpen) _buildReviewForm(),
          ReviewsList(
            reviews: _reviews,
            currentUsername: _currentUsername,
            // Mentre hi ha un formulari obert no deixem editar una altra.
            onEditReview: _isFormOpen ? null : _openEditForm,
          ),
        ],
      ],
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
    if (_reviews.isEmpty) {
      return const Text(
        'Encara no hi ha valoracions.',
        style: TextStyle(fontSize: 14, color: Colors.black54),
      );
    }
    return Row(
      children: [
        const Text(
          'Valoració mitjana: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        RatingStars(
          rating: _averageStars,
          onRatingChanged: (_) {},
          isEnabled: false,
          size: 20,
          spacing: 2,
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
          onPressed: isEditing ? () => _openEditForm(userIdx) : _openAddForm,
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
      key: ValueKey('review-form-${_editingIndex ?? 'new'}'),
      isEditing: editing != null,
      initialGeneralRating: editing?.general ?? 0,
      initialPreuRating: editing?.preu ?? 0,
      initialAmbientRating: editing?.ambient ?? 0,
      initialAccessibilitatRating: editing?.accessibilitat ?? 0,
      initialComment: editing?.comment ?? '',
      onCancel: () => setState(_closeForm),
      onSubmit: _submitReview,
    );
  }
}
