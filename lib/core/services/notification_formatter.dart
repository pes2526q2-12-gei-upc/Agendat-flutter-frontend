import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/services/notification_payload.dart';

const Map<String, Map<String, String>> _localizedActionLabels = {
  'CA': {
    'friend_request.sent': 't\'ha enviat una sol·licitud d\'amistat',
    'friend_request.accepted': 'ha acceptat la teva sol·licitud d\'amistat',
    'chat.message': 't\'ha enviat un missatge',
    'event_invitation.sent': 't\'ha convidat a un esdeveniment',
    'event_invitation.accepted': 'ha acceptat la teva invitació',
    'review.liked': 'ha fet m\'agrada a la teva ressenya',
    'event.reminder': 'comença aviat',
  },
  'ES': {
    'friend_request.sent': 'te ha enviado una solicitud de amistad',
    'friend_request.accepted': 'ha aceptado tu solicitud de amistad',
    'chat.message': 'te ha enviado un mensaje',
    'event_invitation.sent': 'te ha invitado a un evento',
    'event_invitation.accepted': 'ha aceptado tu invitación',
    'review.liked': 'le ha gustado tu reseña',
    'event.reminder': 'empieza pronto',
  },
  'EN': {
    'friend_request.sent': 'sent you a friend request',
    'friend_request.accepted': 'accepted your friend request',
    'chat.message': 'sent you a message',
    'event_invitation.sent': 'invited you to an event',
    'event_invitation.accepted': 'accepted your event invitation',
    'review.liked': 'liked your review',
    'event.reminder': 'starts soon',
  },
};

String? localizedNotificationActionLabel(
  String? actionKey, {
  String? languageCode,
}) {
  if (actionKey == null || actionKey.trim().isEmpty) return null;
  final normalized = _normalizeLanguageCode(languageCode ?? AppLanguage.code);
  return _localizedActionLabels[normalized]?[actionKey] ??
      _localizedActionLabels['EN']?[actionKey];
}

String formatNotificationTitle(
  NotificationPayload notification, {
  String? languageCode,
}) {
  final actionKey = notification.action?.key;
  if (actionKey == 'chat.message') {
    return _firstNonBlank([
          notification.actor?.displayName,
          notification.title,
          notification.target?.name,
          localizedNotificationActionLabel(
            actionKey,
            languageCode: languageCode,
          ),
        ]) ??
        '';
  }

  final localizedAction = localizedNotificationActionLabel(
    actionKey,
    languageCode: languageCode,
  );

  if (localizedAction != null) {
    final actorName = notification.actor?.displayName;
    if (actorName != null && actorName.isNotEmpty) {
      return '$actorName $localizedAction';
    }

    final targetName = notification.target?.name;
    if (targetName != null && targetName.isNotEmpty) {
      return '$targetName $localizedAction';
    }

    return localizedAction;
  }

  return _firstNonBlank([
        notification.title,
        notification.action?.label,
        notification.body,
      ]) ??
      '';
}

String formatNotificationSubtitle(
  NotificationPayload notification, {
  String? languageCode,
}) {
  final title = formatNotificationTitle(
    notification,
    languageCode: languageCode,
  );
  final candidates = notification.action?.key == 'chat.message'
      ? [
          notification.preview?.text,
          notification.body,
          _chatPreviewFallback(
            notification.preview?.kind,
            languageCode: languageCode,
          ),
          notification.target?.name,
        ]
      : [
          notification.preview?.text,
          notification.body,
          notification.target?.name,
        ];

  return _firstNonBlank(candidates, except: title) ?? '';
}

String _normalizeLanguageCode(String code) {
  final upper = code.trim().toUpperCase();
  if (_localizedActionLabels.containsKey(upper)) return upper;
  return 'EN';
}

const Map<String, Map<String, String>> _localizedChatPreviewFallbacks = {
  'CA': {
    'image': 'T\'ha enviat una imatge.',
    'file': 'T\'ha enviat un fitxer.',
    'event_invitation': 'T\'ha enviat una invitació a un esdeveniment.',
  },
  'ES': {
    'image': 'Te ha enviado una imagen.',
    'file': 'Te ha enviado un archivo.',
    'event_invitation': 'Te ha enviado una invitación a un evento.',
  },
  'EN': {
    'image': 'Sent you an image.',
    'file': 'Sent you a file.',
    'event_invitation': 'Sent you an event invitation.',
  },
};

String? _chatPreviewFallback(String? kind, {String? languageCode}) {
  final normalizedKind = kind?.trim();
  if (normalizedKind == null || normalizedKind.isEmpty) return null;
  final normalizedLanguage = _normalizeLanguageCode(
    languageCode ?? AppLanguage.code,
  );
  return _localizedChatPreviewFallbacks[normalizedLanguage]?[normalizedKind] ??
      _localizedChatPreviewFallbacks['EN']?[normalizedKind];
}

String? _firstNonBlank(Iterable<String?> values, {String? except}) {
  final normalizedExcept = except?.trim();
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty && trimmed != normalizedExcept) {
      return trimmed;
    }
  }
  return null;
}
