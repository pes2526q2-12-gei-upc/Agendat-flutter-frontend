/*
Aquest widget representa una fila de chat.
 Inclou:
   - Avatar del remitent.
   - Contingut de l'últim missatge.
   - Data de l'útima interacció amb el chat (si s'ha enviat avui, només es mostra l'hora)
   - una icona de notificació amb el numero de missatges no llegits a la dreta a dalt de l'avatar (si el chat té missatges no llegits)
   
*/

import 'package:agendat/core/models/chat.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/widgets/avatars.dart';
import 'package:flutter/material.dart';

class ChatRow extends StatelessWidget {
  const ChatRow({super.key, required this.chat, this.onTap});

  final Chat chat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final partnerName = chat.partner.displayName;
    final hasUnread = chat.unreadCount > 0;
    final timeLabel = ChatTimestampFormat.listRow(
      context,
      chat.lastMessageTime,
    );

    const avatarRadius = 26.0;
    final avatar = ProfileCircleAvatar(
      radius: avatarRadius,
      profileImage: chat.partner.profileImage,
      fallbackLabel: partnerName,
    );

    final avatarWithBadge = SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, bottom: 0, child: avatar),
          if (hasUnread)
            Positioned(
              right: 0,
              top: -2,
              child: _UnreadBadge(count: chat.unreadCount),
            ),
        ],
      ),
    );

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatarWithBadge,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat.canSend
                          ? chat.lastMessage
                          : (chat.lastMessage.isEmpty
                                ? chat.inactiveMessagingReasonShort
                                : '${chat.inactiveMessagingReasonShort} · ${chat.lastMessage}'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: chat.canSend ? Colors.black54 : Colors.black45,
                        height: 1.25,
                        fontStyle: chat.canSend
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasUnread ? Colors.red : Colors.black45,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  String get label {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
            height: 1,
          ),
        ),
      ),
    );
  }
}
