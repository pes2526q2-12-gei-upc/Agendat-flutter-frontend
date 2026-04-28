import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/reviews/presentation/widgets/review_rating_row.dart';
import 'package:agendat/main.dart' show RootNavigationScreen;

/// Targeta que pinta una única [Review] en mode lectura.
///
/// Inclou:
///   - Capçalera amb avatar (inicial de l'autor), nom i data.
///   - Una fila d'estrelles amb la puntuació General.
///   - Comentari de text (si n'hi ha).
///   - Galeria horitzontal d'imatges adjuntes (si n'hi ha).
///   - Peu amb botó de like i comptador.
///
/// Si es passa [onEdit] (i la valoració és de l'usuari loggejat) apareix
/// una icona de llapis a la capçalera. Si es passa [onDelete] (també
/// només per valoracions pròpies) apareix una icona de paperera.
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.onLikeToggle,
    this.isLikeBusy = false,
  });

  final Review review;

  /// Callback per entrar en mode edició. Si és `null` no es mostra el botó.
  final VoidCallback? onEdit;

  /// Callback per eliminar la valoració. Si és `null` no es mostra el botó.
  final VoidCallback? onDelete;

  /// Callback per alternar el like. Si és `null` el botó queda deshabilitat
  /// (p. ex. quan l'usuari no està autenticat).
  final VoidCallback? onLikeToggle;

  /// Deshabilita el botó de like mentre hi ha una petició en curs.
  final bool isLikeBusy;

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
          _buildHeader(context),
          const SizedBox(height: 10),
          ReviewRatingRow(label: 'Valoració general', rating: review.general),
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
          const SizedBox(height: 10),
          _buildFooter(),
        ],
      ),
    );
  }

  bool get _hasComment =>
      review.comment != null && review.comment!.trim().isNotEmpty;

  /// Capçalera: avatar (foto de perfil o inicial), nom, data i botons
  /// d'edició/esborrat (aquests últims només per valoracions pròpies).
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        _buildAuthorAvatar(context),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: _canOpenAuthorProfile
                ? () => _openAuthorProfile(context)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                review.author,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
        Text(
          _formatDate(review.date),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          _iconButton(icon: Icons.edit_rounded, onTap: onEdit!),
        ],
        if (onDelete != null) ...[
          const SizedBox(width: 2),
          _iconButton(icon: Icons.delete_outline_rounded, onTap: onDelete!),
        ],
      ],
    );
  }

  /// Avatar circular. Si hi ha foto de perfil la pintem; altrament mostrem
  /// la inicial del nom com a fallback.
  Widget _buildAuthorAvatar(BuildContext context) {
    final avatarUrl = resolveProfileImageUrl(review.authorAvatarUrl);
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final initial = review.author.isNotEmpty
        ? review.author[0].toUpperCase()
        : '?';

    return InkWell(
      onTap: _canOpenAuthorProfile ? () => _openAuthorProfile(context) : null,
      borderRadius: BorderRadius.circular(18),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: _brandRed,
        backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
        onBackgroundImageError: hasAvatar ? (_, __) {} : null,
        child: hasAvatar
            ? null
            : Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }

  int? get _authorUserId => int.tryParse(review.authorId ?? '');

  int? get _currentUserId => (currentLoggedInUser?['id'] as num?)?.toInt();

  bool get _isOwnReview =>
      _authorUserId != null && _currentUserId == _authorUserId;

  bool get _canOpenAuthorProfile => _isOwnReview || _authorUserId != null;

  void _openAuthorProfile(BuildContext context) {
    if (_isOwnReview) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const RootNavigationScreen(initialIndex: 4),
        ),
      );
      return;
    }

    // El backend envia reviewer_id; el fem servir per obrir el perfil.
    final userId = _authorUserId;
    if (userId == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)));
  }

  /// Formata una data ISO (com la que retorna el backend) a
  /// `dd/MM/yyyy HH:mm`. Si el string no és parsejable, el retorna tal qual.
  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  /// Peu de la targeta amb el botó de like i el comptador.
  Widget _buildFooter() {
    final liked = review.isLikedByMe;
    final count = review.likesCount;
    final isDisabled = onLikeToggle == null || isLikeBusy;

    return Row(
      children: [
        InkWell(
          onTap: isDisabled ? null : onLikeToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isDisabled
                      ? Colors.grey.shade400
                      : (liked ? _brandRed : Colors.grey.shade600),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDisabled ? Colors.grey.shade400 : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 18, color: _brandRed),
      ),
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
