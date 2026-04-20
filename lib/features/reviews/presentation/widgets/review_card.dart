import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';

/// Targeta que pinta una única [Review] en mode lectura.
///
/// Inclou:
///   - Capçalera amb avatar (inicial de l'autor), nom i data.
///   - 4 files d'estrelles (General, Preu, Ambient, Accessibilitat).
///   - Comentari de text (si n'hi ha).
///   - Galeria horitzontal d'imatges adjuntes (si n'hi ha).
///
/// Si es passa [onEdit], a la capçalera apareix una icona de llapis perquè
/// l'usuari pugui editar la valoració. Només s'hauria de passar per a les
/// ressenyes de l'usuari loggejat.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review, this.onEdit});

  final Review review;

  /// Callback per entrar en mode edició. Si és `null`, no es mostra el
  /// botó de llapis.
  final VoidCallback? onEdit;

  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          ReviewRatingRow(label: 'General', rating: review.general),
          ReviewRatingRow(label: 'Preu', rating: review.preu),
          ReviewRatingRow(label: 'Ambient', rating: review.ambient),
          ReviewRatingRow(
            label: 'Accessibilitat',
            rating: review.accessibilitat,
          ),
          if (_hasComment) ...[
            const SizedBox(height: 8),
            Text(
              review.comment!.trim(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildImagesGallery(),
          ],
        ],
      ),
    );
  }

  bool get _hasComment =>
      review.comment != null && review.comment!.trim().isNotEmpty;

  /// Capçalera: avatar amb la inicial, nom, data i (si escau) botó d'edició.
  Widget _buildHeader() {
    final initial = review.author.isNotEmpty
        ? review.author[0].toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _brandRed,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            review.author,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          review.date,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit_rounded, size: 18, color: _brandRed),
            ),
          ),
        ],
      ],
    );
  }

  /// Galeria horitzontal d'imatges adjuntes a la valoració.
  /// TODO(backend): quan el servidor suporti també vídeos, distingir el
  /// tipus de mitjà i mostrar un reproductor per als vídeos.
  Widget _buildImagesGallery() {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: review.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              review.imageUrls[index],
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 70,
                height: 70,
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
