import 'package:flutter/foundation.dart';

/// Centralised source of truth for the language the app is currently asking
/// the backend to translate content into.
///
/// The values match the `lang` query parameter accepted by the events API
/// (`CA`, `ES`, `EN`). When the app is in Catalan we keep [code] as
/// [defaultCode] (`CA`) so [requiresTranslation] stays `false` and we don't
/// burn translation quota.
class AppLanguage {
  /// Default language returned by the backend when no `lang` is passed.
  static const String defaultCode = 'CA';

  /// Supported language codes.
  static const Set<String> supported = {'CA', 'ES', 'EN'};

  AppLanguage._();

  static final ValueNotifier<String> _current = ValueNotifier<String>(
    defaultCode,
  );

  /// Current language code (always uppercase, always within [supported]).
  static String get code => _current.value;

  /// Listenable so widgets can rebuild when the language changes.
  static ValueListenable<String> get listenable => _current;

  /// `true` when the backend will translate events instead of returning the
  /// original Catalan content.
  ///
  /// Used by the events list to decide how many events to fetch per page —
  /// we keep pages small in this case to respect the translation quota.
  static bool get requiresTranslation => code.toUpperCase() != defaultCode;

  /// Updates the language used for events translations. No-op when [value]
  /// resolves to the current language.
  static void setCode(String value) {
    final normalized = _normalize(value);
    if (normalized == _current.value) return;
    _current.value = normalized;
  }

  static String _normalize(String value) {
    final upper = value.trim().toUpperCase();
    if (supported.contains(upper)) return upper;
    return defaultCode;
  }
}
