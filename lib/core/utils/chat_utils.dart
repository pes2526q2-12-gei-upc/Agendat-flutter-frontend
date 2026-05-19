import 'package:agendat/core/utils/profile_image_url.dart';
import 'package:flutter/material.dart';

/// URL per `NetworkImage` (via [resolveProfileImageUrl]) o `null` si no n’hi ha.
String? chatProfileImageUrl(String? rawProfileImageField) {
  final u = resolveProfileImageUrl(rawProfileImageField)?.trim();
  if (u == null || u.isEmpty) return null;
  return u;
}

/// URL absoluta per mostrar mitjans adjunts del xat.
String? chatMediaUrl(String? rawMediaField) {
  final u = resolveProfileImageUrl(rawMediaField)?.trim();
  if (u == null || u.isEmpty) return null;
  return u;
}

/// Inicials curtes per avatars del xat (no depèn del paquet `characters`).
String chatAvatarInitials(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '?';
  final parts = raw
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  final word = parts[0];
  if (word.length >= 2) return word.substring(0, 2).toUpperCase();
  return word.toUpperCase();
}

/// Format de dates al xat, amb Material localizations.
abstract final class ChatTimestampFormat {
  ChatTimestampFormat._();

  /// Filera de la llista: avui només hora; sinó data compacta.
  static String listRow(BuildContext context, DateTime at) {
    final locale = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final tod = TimeOfDay(hour: at.hour, minute: at.minute);
    if (DateUtils.isSameDay(at, now)) return locale.formatTimeOfDay(tod);
    return locale.formatCompactDate(at);
  }

  /// Bombolla de missatge: avui només hora; sinó data + hora.
  static String messageDetail(BuildContext context, DateTime at) {
    final locale = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final tod = TimeOfDay(hour: at.hour, minute: at.minute);
    if (DateUtils.isSameDay(at, now)) return locale.formatTimeOfDay(tod);
    return '${locale.formatCompactDate(at)} · ${locale.formatTimeOfDay(tod)}';
  }
}

/// Parseja valors típics d’API (ISO string, ms o s unix). Fallback: epoch 0.
DateTime parseFlexibleDateTime(Object? value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (value is num) {
    final n = value.toInt();
    if (n > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(n);
    return DateTime.fromMillisecondsSinceEpoch(n * 1000);
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}
