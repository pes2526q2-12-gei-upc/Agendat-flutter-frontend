/*
Aquest widget representa un missatge de chat.
 Inclou:
   - Avatar del remitent.
   - Contingut del missatge.
   - Data i hora de l'enviament (si s'ha enviat avui, només es mostra l'hora)
   - Color de fons del missatge (si l'usuari és el remitent, el color és vermell (seguint el disseny de la app), si no, el color és blanc)

*/

import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/widgets/avatars.dart';
import 'package:flutter/material.dart';

class Message extends StatelessWidget {
  const Message({
    super.key,
    required this.messageText,
    required this.sentAt,
    required this.isSentByMe,
    this.imageUrl,
    this.avatarUrl,
    this.avatarLabel,
    this.receiptLabel,
  });

  final String messageText;
  final DateTime sentAt;
  final bool isSentByMe;
  final String? imageUrl;

  /// Imatge de perfil del remitent (relativa o URL completa).
  final String? avatarUrl;

  /// Text per inicials si no hi ha foto.
  final String? avatarLabel;
  final String? receiptLabel;
  static const Color _sentBubbleColor = AppThemeTokens.brandPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isSentByMe ? _sentBubbleColor : Colors.white;
    final onBubble = isSentByMe ? Colors.white : Colors.black87;
    final timeLabel = ChatTimestampFormat.messageDetail(context, sentAt);
    final resolvedImageUrl = chatMediaUrl(imageUrl);
    final hasImage = resolvedImageUrl != null;
    final hasText = messageText.trim().isNotEmpty;

    const avatarRadius = 18.0;
    final avatar = ProfileCircleAvatar(
      radius: avatarRadius,
      profileImage: avatarUrl,
      fallbackLabel: avatarLabel ?? '?',
    );
    final hasReceiptLabel =
        receiptLabel != null && receiptLabel!.trim().isNotEmpty;

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isSentByMe ? 16 : 4),
          bottomRight: Radius.circular(isSentByMe ? 4 : 16),
        ),
        border: isSentByMe ? null : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasImage) ...[
            _MessageImage(
              imageUrl: resolvedImageUrl,
              isSentByMe: isSentByMe,
            ),
            if (hasText) const SizedBox(height: 8),
          ],
          if (hasText)
            SelectableText(
              messageText,
              style: theme.textTheme.bodyMedium?.copyWith(color: onBubble),
            ),
          if (hasImage || hasText) const SizedBox(height: 4),
          Text(
            timeLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: onBubble.withValues(alpha: isSentByMe ? 0.85 : 0.55),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    final bubbleWithReceipt = Column(
      crossAxisAlignment: isSentByMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        bubble,
        if (hasReceiptLabel) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              receiptLabel!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.black54,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe) ...[avatar, const SizedBox(width: 8)],
          Expanded(
            child: Align(
              alignment: isSentByMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: bubbleWithReceipt,
            ),
          ),
          if (isSentByMe) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }

}

class _MessageImage extends StatelessWidget {
  const _MessageImage({
    required this.imageUrl,
    required this.isSentByMe,
  });

  final String imageUrl;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final fallbackColor = isSentByMe
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.grey.shade100;
    final fallbackIconColor = isSentByMe ? Colors.white70 : Colors.black38;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 280,
          maxHeight: 260,
        ),
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: fallbackColor,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes == null
                        ? null
                        : loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Container(
              color: fallbackColor,
              alignment: Alignment.center,
              child: Icon(Icons.broken_image_outlined, color: fallbackIconColor),
            ),
          ),
        ),
      ),
    );
  }
}
