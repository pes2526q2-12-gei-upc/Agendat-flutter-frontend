/*
Aquest widget representa un missatge de chat.
 Inclou:
   - Avatar del remitent.
   - Contingut del missatge.
   - Data i hora de l'enviament (si s'ha enviat avui, només es mostra l'hora)
   - Color de fons del missatge (si l'usuari és el remitent, el color és vermell (seguint el disseny de la app), si no, el color és blanc)

*/

import 'package:agendat/core/utils/chat_utils.dart';
import 'package:flutter/material.dart';

class Message extends StatelessWidget {
  const Message({
    super.key,
    required this.messageText,
    required this.sentAt,
    required this.isSentByMe,
    this.avatarUrl,
    this.avatarLabel,
  });

  final String messageText;
  final DateTime sentAt;
  final bool isSentByMe;

  /// Imatge de perfil del remitent (relativa o URL completa).
  final String? avatarUrl;

  /// Text per inicials si no hi ha foto.
  final String? avatarLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isSentByMe ? Colors.red : Colors.white;
    final onBubble = isSentByMe ? Colors.white : Colors.black87;
    final timeLabel = ChatTimestampFormat.messageDetail(context, sentAt);

    final avatarUrlResolved = chatProfileImageUrl(avatarUrl);
    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: avatarUrlResolved != null
          ? NetworkImage(avatarUrlResolved)
          : null,
      child: avatarUrlResolved == null
          ? Text(
              chatAvatarInitials(avatarLabel ?? '?'),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            )
          : null,
    );

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
          SelectableText(
            messageText,
            style: theme.textTheme.bodyMedium?.copyWith(color: onBubble),
          ),
          const SizedBox(height: 4),
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
              child: bubble,
            ),
          ),
          if (isSentByMe) ...[const SizedBox(width: 8), avatar],
        ],
      ),
    );
  }
}
