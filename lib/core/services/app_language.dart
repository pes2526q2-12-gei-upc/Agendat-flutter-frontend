import 'package:flutter/foundation.dart';

/// Source of truth per a la llengua activa de la UI de l'app.
///
/// La traducció dels esdeveniments la fa el backend a partir de l'idioma
/// que l'usuari té guardat al perfil; aquí només mantenim l'estat per si
/// algun text de la interfície local s'ha d'adaptar.
class AppLanguage {
  /// Codi per defecte.
  static const String defaultCode = 'CA';

  /// Codis suportats.
  static const Set<String> supported = {'CA', 'ES', 'EN'};

  AppLanguage._();

  static final ValueNotifier<String> _current = ValueNotifier<String>(
    defaultCode,
  );

  /// Codi d'idioma actual (sempre majúscules, sempre dins de [supported]).
  static String get code => _current.value;

  /// Listenable perquè els widgets puguin reaccionar quan canvia.
  static ValueListenable<String> get listenable => _current;

  /// Actualitza l'idioma actiu. No-op si [value] coincideix amb l'actual.
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
