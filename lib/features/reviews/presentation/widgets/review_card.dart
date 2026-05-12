import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/models/review.dart';
import 'package:agendat/core/utils/profile_image_url.dart';
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
class ReviewCard extends StatefulWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.onLikeToggle,
    this.onLanguageChanged,
    this.isLikeBusy = false,
    this.isTranslating = false,
    this.translatedComment,
  });

  final Review review;

  /// Callback per entrar en mode edició. Si és `null` no es mostra el botó.
  final VoidCallback? onEdit;

  /// Callback per eliminar la valoració. Si és `null` no es mostra el botó.
  final VoidCallback? onDelete;

  /// Callback per alternar el like. Si és `null` el botó queda deshabilitat
  /// (p. ex. quan l'usuari no està autenticat).
  final VoidCallback? onLikeToggle;

  /// Callback quan l'usuari canvia l'idioma del menú.
  final ValueChanged<String>? onLanguageChanged;

  /// Deshabilita el botó de like mentre hi ha una petició en curs.
  final bool isLikeBusy;

  /// Indica si hi ha una petició de traducció en curs.
  final bool isTranslating;

  /// Comentari traduït retornat pel backend per a l'idioma seleccionat.
  final String? translatedComment;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  static const Color _brandRed = Color.fromARGB(255, 202, 3, 3);
  String _language = '';

  void _handleLanguageChanged(String value) {
    setState(() => _language = value);
    widget.onLanguageChanged?.call(value);
  }

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
          ReviewRatingRow(
            label: 'Valoració general',
            rating: widget.review.general,
          ),
          if (_hasComment) ...[
            const SizedBox(height: 8),
            Text(
              widget.review.comment!.trim(),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            if (_hasTranslatedComment) ...[
              const SizedBox(height: 8),
              Text(
                widget.translatedComment!.trim(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
          if (widget.review.imageUrls.isNotEmpty) ...[
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
      widget.review.comment != null && widget.review.comment!.trim().isNotEmpty;

  bool get _hasTranslatedComment =>
      widget.translatedComment != null &&
      widget.translatedComment!.trim().isNotEmpty;

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
                widget.review.author,
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
          _formatDate(widget.review.date),
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        if (widget.onEdit != null) ...[
          const SizedBox(width: 4),
          _iconButton(icon: Icons.edit_rounded, onTap: widget.onEdit!),
        ],
        if (widget.onDelete != null) ...[
          const SizedBox(width: 2),
          _iconButton(
            icon: Icons.delete_outline_rounded,
            onTap: widget.onDelete!,
          ),
        ],
      ],
    );
  }

  /// Avatar circular. Si hi ha foto de perfil la pintem; altrament mostrem
  /// la inicial del nom com a fallback.
  Widget _buildAuthorAvatar(BuildContext context) {
    final avatarUrl = resolveProfileImageUrl(widget.review.authorAvatarUrl);
    final hasAvatar = avatarUrl != null && avatarUrl.trim().isNotEmpty;
    final initial = widget.review.author.isNotEmpty
        ? widget.review.author[0].toUpperCase()
        : '?';

    Widget fallbackAvatar() {
      return CircleAvatar(
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
      );
    }

    final child = hasAvatar
        ? ClipOval(
            child: SizedBox(
              width: 32,
              height: 32,
              child: Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                webHtmlElementStrategy: kIsWeb
                    ? WebHtmlElementStrategy.prefer
                    : WebHtmlElementStrategy.never,
                errorBuilder: (_, __, ___) => fallbackAvatar(),
              ),
            ),
          )
        : fallbackAvatar();

    return InkWell(
      onTap: _canOpenAuthorProfile ? () => _openAuthorProfile(context) : null,
      borderRadius: BorderRadius.circular(18),
      child: child,
    );
  }

  int? get _authorUserId => int.tryParse(widget.review.authorId ?? '');

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
    final liked = widget.review.isLikedByMe;
    final count = widget.review.likesCount;
    final isDisabled = widget.onLikeToggle == null || widget.isLikeBusy;

    return Row(
      children: [
        InkWell(
          onTap: isDisabled ? null : widget.onLikeToggle,
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
        const Spacer(),
        PopupMenuButton<String>(
          tooltip: 'Traduïr',
          enabled: !widget.isTranslating,
          onSelected: _handleLanguageChanged,
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'CA', child: Text('CA')),
            PopupMenuItem(value: 'ES', child: Text('ES')),
            PopupMenuItem(value: 'EN', child: Text('EN')),
          ],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isTranslating)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade600,
                  ),
                )
              else
                Icon(Icons.translate, size: 20, color: Colors.grey.shade600),
              if (_language.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  _language,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ],
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
  Widget _buildImagesGallery() {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.review.imageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              widget.review.imageUrls[index],
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
