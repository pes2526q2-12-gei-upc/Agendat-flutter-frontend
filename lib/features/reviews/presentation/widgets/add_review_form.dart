import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';

/// Formulari inline per afegir o editar una valoració d'un esdeveniment.
///
/// Conté 4 files de puntuació (General, Preu, Ambient, Accessibilitat),
/// un camp de comentari opcional i un selector d'imatges/vídeos.
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

  /// Si és `true` es mostra el títol "EDITAR VALORACIÓ" i el botó "Desar";
  /// altrament es mostra "AFEGIR VALORACIÓ" i "Afegir".
  final bool isEditing;

  @override
  State<AddReviewForm> createState() => _AddReviewFormState();
}

class _AddReviewFormState extends State<AddReviewForm> {
  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);
  static const int _maxCommentLength = 500;
  static const int _maxMediaCount = 5;
  static const List<String> _allowedExtensions = [
    'png',
    'jpg',
    'jpeg',
    'gif',
    'webp',
    'mp4',
    'mov',
  ];

  late int _generalRating = widget.initialGeneralRating;
  late int _preuRating = widget.initialPreuRating;
  late int _ambientRating = widget.initialAmbientRating;
  late int _accessibilitatRating = widget.initialAccessibilitatRating;

  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment,
  );

  // TODO(backend): en mode edició caldria carregar també els mitjans
  // que ja existien al servidor (URLs) i deixar que l'usuari en tregui
  // o n'afegeixi de nous.
  final List<XFile> _selectedMedia = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  /// Valida i envia el formulari. Totes les puntuacions han de tenir
  /// almenys 1 estrella; altrament es mostra un avís i no es crida
  /// `onSubmit`.
  void _submitForm() {
    final missing = <String>[];
    if (_generalRating == 0) missing.add('General');
    if (_preuRating == 0) missing.add('Preu');
    if (_ambientRating == 0) missing.add('Ambient');
    if (_accessibilitatRating == 0) missing.add('Accessibilitat');
    if (missing.isNotEmpty) {
      _showSnack(
        missing.length == 1
            ? 'Has de posar almenys 1 estrella a ${missing.first}.'
            : 'Totes les puntuacions han de tenir almenys 1 estrella.',
      );
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

  /// Obre el selector de la galeria i afegeix els fitxers vàlids que
  /// es triïn (respectant la mida màxima i les extensions permeses).
  Future<void> _pickMedia() async {
    if (_selectedMedia.length >= _maxMediaCount) {
      _showSnack('Màxim $_maxMediaCount fitxers permesos.');
      return;
    }

    final picked = await ImagePicker().pickMultiImage();
    for (final file in picked) {
      final ext = file.path.split('.').last.toLowerCase();
      if (!_allowedExtensions.contains(ext)) {
        _showSnack('Format no permès: .$ext');
        continue;
      }
      if (_selectedMedia.length >= _maxMediaCount) break;
      setState(() => _selectedMedia.add(file));
    }
  }

  void _removeMediaAt(int index) {
    setState(() => _selectedMedia.removeAt(index));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black87,
    );
    return Column(
      children: [
        ReviewRatingRow(
          label: 'General',
          rating: _generalRating,
          onRatingChanged: (v) => setState(() => _generalRating = v),
          labelWidth: 110,
          labelStyle: labelStyle,
          starSize: 30,
          starSpacing: 4,
          bottomSpacing: 10,
        ),
        ReviewRatingRow(
          label: 'Preu',
          rating: _preuRating,
          onRatingChanged: (v) => setState(() => _preuRating = v),
          labelWidth: 110,
          labelStyle: labelStyle,
          starSize: 30,
          starSpacing: 4,
          bottomSpacing: 10,
        ),
        ReviewRatingRow(
          label: 'Ambient',
          rating: _ambientRating,
          onRatingChanged: (v) => setState(() => _ambientRating = v),
          labelWidth: 110,
          labelStyle: labelStyle,
          starSize: 30,
          starSpacing: 4,
          bottomSpacing: 10,
        ),
        ReviewRatingRow(
          label: 'Accessibilitat',
          rating: _accessibilitatRating,
          onRatingChanged: (v) => setState(() => _accessibilitatRating = v),
          labelWidth: 110,
          labelStyle: labelStyle,
          starSize: 30,
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
      label: Text(
        'Afegir fotos/videos (${_selectedMedia.length}/$_maxMediaCount)',
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black54,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
                child: Image.file(
                  File(_selectedMedia[index].path),
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
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
