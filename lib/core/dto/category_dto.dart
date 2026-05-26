import 'package:agendat/core/services/app_language.dart';

class CategoryDto {
  final int? id;
  final String name;
  final String? emoji;

  const CategoryDto({this.id, required this.name, this.emoji});

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final emoji = ((json['emoji'] ?? '') as String).trim();
    final name = _localizedName(json) ?? _stringOrNull(json['name']) ?? '';
    return CategoryDto(
      id: json['id'] as int?,
      name: name,
      emoji: emoji.isEmpty ? null : emoji,
    );
  }

  static String? _localizedName(Map<String, dynamic> json) {
    final code = AppLanguage.code.trim().toUpperCase();
    final candidates = switch (code) {
      'ES' => const ['name_es', 'nameES', 'name_spanish', 'nombre', 'es'],
      'EN' => const ['name_en', 'nameEN', 'name_english', 'english_name', 'en'],
      _ => const [
        'name_ca',
        'nameCA',
        'name_cat',
        'name_catalan',
        'catalan_name',
        'nom',
        'ca',
      ],
    };

    for (final key in candidates) {
      final value = _stringOrNull(json[key]);
      if (value != null) return value;
    }

    final translations = json['translations'];
    if (translations is Map<String, dynamic>) {
      final translated = translations[code] ?? translations[code.toLowerCase()];
      final value = _stringOrNull(translated);
      if (value != null) return value;
      if (translated is Map<String, dynamic>) {
        return _stringOrNull(translated['name']);
      }
    }

    return null;
  }

  static String? _stringOrNull(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
