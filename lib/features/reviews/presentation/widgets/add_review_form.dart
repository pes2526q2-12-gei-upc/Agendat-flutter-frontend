import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/core/api/reviews_api.dart' show ReviewsApi;
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';

/// Formulari inline per afegir o editar una valoració d'un esdeveniment.
///
/// Conté 4 files de puntuació (General, Preu, Ambient, Accessibilitat),
/// un camp de comentari opcional i un selector de fotos (png, jpg, jpeg).
/// Quan l'usuari prem "Afegir" (o "Desar" en mode edició) es crida
/// [onSubmit] amb els valors seleccionats. El pare (`ReviewsSection`)
/// s'encarrega d'enviar-ho al servidor.
class AddReviewForm extends StatefulWidget {
  const AddReviewForm({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.initialGeneralRating = 0,
    this.initialPreuRating = 0,
    this.initialAmbientRating = 0,
    this.initialAccessibilitatRating = 0,
    this.initialComment = '',
    this.isEditing = false,
    this.initialImageCount = 0,
  });

  /// Callback amb les dades introduïdes. Es crida només si la validació
  /// bàsica (General > 0) passa.
  final void Function({
    required int generalRating,
    required int preuRating,
    required int ambientRating,
    required int accessibilitatRating,
    required String comment,
    required List<XFile> media,
  })
  onSubmit;

  /// Es crida quan l'usuari prem "Cancel·lar" i tanca el formulari
  /// sense desar res.
  final VoidCallback onCancel;

  final int initialGeneralRating;
  final int initialPreuRating;
  final int initialAmbientRating;
  final int initialAccessibilitatRating;
  final String initialComment;
  final int initialImageCount;

  /// Si és `true` es mostra el títol "EDITAR VALORACIÓ" i el botó "Desar";
  /// altrament es mostra "AFEGIR VALORACIÓ" i "Afegir".
  final bool isEditing;

  @override
  State<AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<AddReviewForm> {
  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);
  static const int _maxCommentLength = 500;
  static const int _maxMediaCount = ReviewsApi.maxImagesPerReview;
  static const List<String> _allowedExtensions = ['png', 'jpg', 'jpeg'];

  late int _generalRating = widget.initialGeneralRating;
  late int _preuRating = widget.initialPreuRating;
  late int _ambientRating = widget.initialAmbientRating;
  late int _accessibilitatRating = widget.initialAccessibilitatRating;

  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment,
  );

  final List<XFile> _selectedMedia = [];

  int get _existingMediaCount =>
      widget.initialImageCount < 0 ? 0 : widget.initialImageCount;

  int get _totalMediaCount => _existingMediaCount + _selectedMedia.length;

  static const _ratingInputStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  List<_RatingInputConfig> get _ratingConfigs => [
    _RatingInputConfig(
      label: 'General',
      rating: _generalRating,
      starSize: ReviewRatingRow.formGeneralStarSize,
      onChanged: (v) => setState(() => _generalRating = v),
    ),
    _RatingInputConfig(
      label: 'Preu',
      rating: _preuRating,
      starSize: ReviewRatingRow.formOtherCategoriesStarSize,
      onChanged: (v) =>
          setState(() => _preuRating = _optionalRatingAfterTap(_preuRating, v)),
    ),
    _RatingInputConfig(
      label: 'Ambient',
      rating: _ambientRating,
      starSize: ReviewRatingRow.formOtherCategoriesStarSize,
      onChanged: (v) => setState(
        () => _ambientRating = _optionalRatingAfterTap(_ambientRating, v),
      ),
    ),
    _RatingInputConfig(
      label: 'Accessibilitat',
      rating: _accessibilitatRating,
      starSize: ReviewRatingRow.formOtherCategoriesStarSize,
      onChanged: (v) => setState(
        () => _accessibilitatRating = _optionalRatingAfterTap(
          _accessibilitatRating,
          v,
        ),
      ),
    ),
  ];

  /// Preu, ambient i accessibilitat poden ser 0. Si la puntuació és 1 i es
  /// torna a prémer la primera estrella, es deixa a 0 (General no: mínim 1).
  int _optionalRatingAfterTap(int current, int tapped) {
    if (tapped == 1 && current == 1) return 0;
    return tapped;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Valida i envia el formulari. General ha de tenir com a mínim 1 estrella;
  /// la resta de categories poden quedar a 0.
  void _submitForm() {
    if (_generalRating == 0) {
      _showSnack('Has de posar almenys 1 estrella a General.');
      return;
    }
    widget.onSubmit(
      generalRating: _generalRating,
      preuRating: _preuRating,
      ambientRating: _ambientRating,
      accessibilitatRating: _accessibilitatRating,
      comment: _commentController.text,
      media: _selectedMedia,
    );
  }

  /// Extensió normalitzada (p. ex. `png`). El [XFile.path] sovint és un tmp
  /// sense extensió (p. ex. iOS); [XFile.name] acostuma a conservar-la.
  String? _reviewPickExtension(XFile file) {
    String? fromBasename(String raw) {
      final base = raw.replaceAll('\\', '/').split('/').last;
      final clean = base.split('?').first.split('#').first;
      final dot = clean.lastIndexOf('.');
      if (dot <= 0 || dot >= clean.length - 1) return null;
      return clean.substring(dot + 1).toLowerCase();
    }

    final fromName = fromBasename(file.name);
    if (fromName != null && fromName.isNotEmpty) return fromName;

    final fromPath = fromBasename(file.path);
    if (fromPath != null && fromPath.isNotEmpty) return fromPath;

    switch (file.mimeType?.toLowerCase().trim()) {
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
      case 'image/pjpeg':
        return 'jpeg';
      default:
        return null;
    }
  }

  /// Obre el selector de la galeria i afegeix els fitxers vàlids que
  /// es triïn (respectant la mida màxima i les extensions permeses).
  Future<void> _pickMedia() async {
    if (_totalMediaCount >= _maxMediaCount) {
      _showSnack('Màxim $_maxMediaCount fitxers permesos.');
      return;
    }

    final picked = await ImagePicker().pickMultiImage();
    for (final file in picked) {
      final ext = _reviewPickExtension(file);
      if (ext == null || !_allowedExtensions.contains(ext)) {
        _showSnack(
          ext == null
              ? 'No s\'ha pogut detectar el format de la imatge.'
              : 'Format no permès: .$ext',
        );
        continue;
      }
      if (_totalMediaCount >= _maxMediaCount) break;
      setState(() => _selectedMedia.add(file));
    }
  }

  void _removeMediaAt(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
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
          _buildTitle(),
          const SizedBox(height: 14),
          _buildRatingInputs(),
          const SizedBox(height: 12),
          _buildCommentField(),
          const SizedBox(height: 8),
          _buildAddMediaButton(),
          if (_selectedMedia.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSelectedMediaPreview(),
          ],
          const SizedBox(height: 14),
          _buildAllowedFormatsHint(),
          const SizedBox(height: 14),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.isEditing ? 'EDITAR VALORACIÓ' : 'AFEGIR VALORACIÓ',
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: _brandRed,
        letterSpacing: 1.1,
      ),
    );
  }

  /// Les 4 files de puntuació en mode edició (estrelles clicables).
  Widget _buildRatingInputs() {
    return Column(
      children: [
        for (final config in _ratingConfigs)
          ReviewRatingRow(
            label: config.label,
            rating: config.rating,
            onRatingChanged: config.onChanged,
            labelWidth: 110,
            labelStyle: _ratingInputStyle,
            starSize: config.starSize,
            starSpacing: 4,
            bottomSpacing: 10,
          ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextField(
      controller: _commentController,
      maxLength: _maxCommentLength,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Escriu un comentari (opcional)...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _brandRed),
        ),
      ),
    );
  }

  Widget _buildAddMediaButton() {
    return OutlinedButton.icon(
      onPressed: _pickMedia,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: Text('Afegir fotos ($_totalMediaCount/$_maxMediaCount)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black54,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Vista prèvia d'una imatge triada. A web, [Image.file] no està suportat;
  /// el path del picker acostuma a ser un URL `blob:` vàlid per [Image.network].
  Widget _pickedImagePreview(XFile file) {
    const w = 70.0;
    const h = 70.0;
    if (kIsWeb) {
      return Image.network(
        file.path,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          width: w,
          height: h,
          child: Icon(Icons.broken_image_outlined, size: 28),
        ),
      );
    }
    return Image.file(File(file.path), width: w, height: h, fit: BoxFit.cover);
  }

  /// Miniatures horitzontals dels mitjans escollits, amb botó per treure'ls.
  Widget _buildSelectedMediaPreview() {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _pickedImagePreview(_selectedMedia[index]),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _removeMediaAt(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllowedFormatsHint() {
    return Text(
      'Formats permesos: ${_allowedExtensions.join(", ")}',
      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
    );
  }

  /// Fila de botons "Cancel·lar" i "Afegir"/"Desar".
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black54,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancel·lar'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandRed,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(widget.isEditing ? 'Desar' : 'Afegir'),
          ),
        ),
      ],
    );
  }
}

class _RatingInputConfig {
  const _RatingInputConfig({
    required this.label,
    required this.rating,
    required this.starSize,
    required this.onChanged,
  });

  final String label;
  final int rating;
  final double starSize;
  final ValueChanged<int> onChanged;
}
