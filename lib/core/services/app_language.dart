import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _storageKey = 'preferred_language_code';

  /// Etiquetes del selector (sempre en català).
  static const Map<String, String> displayNamesByCode = {
    'CA': 'Català',
    'EN': 'English',
    'ES': 'Español',
  };

  AppLanguage._();

  static final ValueNotifier<String> _current = ValueNotifier<String>(
    defaultCode,
  );

  /// Codi d'idioma actual (sempre majúscules, sempre dins de [supported]).
  static String get code => _current.value;

  /// Listenable perquè els widgets puguin reaccionar quan canvia.
  static ValueListenable<String> get listenable => _current;

  /// Carrega la preferència des de [SharedPreferences] abans d'arrencar l'app.
  static Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored == null) return;
    setCode(stored);
  }

  /// Desa el codi actual a [SharedPreferences].
  static Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _current.value);
  }

  /// Sincronitza l'idioma local amb el valor del perfil d'usuari al backend.
  static Future<void> syncFromBackend(String? selectedLanguage) async {
    if (selectedLanguage == null || selectedLanguage.trim().isEmpty) return;
    setCode(selectedLanguage);
    await persist();
  }

  /// Converteix el codi actiu a [Locale] per a MaterialApp o capçaleres HTTP.
  static Locale toLocale([String? code]) {
    switch (_normalize(code ?? _current.value)) {
      case 'ES':
        return const Locale('es');
      case 'EN':
        return const Locale('en');
      case 'CA':
      default:
        return const Locale('ca');
    }
  }

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
