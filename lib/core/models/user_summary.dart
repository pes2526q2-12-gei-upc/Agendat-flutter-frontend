import 'package:agendat/core/utils/profile_image_json.dart';

/// Representació lleugera d'un usuari per als resultats del cercador.
/// Es construeix a partir de la resposta de GET /api/users/.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    this.reputation,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.description,
  });

  final int id;
  final String username;
  final double? reputation;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String? description;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: _parseId(json),
      username: (json['username'] as String?) ?? '',
      reputation: ((json['reputacio'] ?? json['reputation']) as num?)
          ?.toDouble(),
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: profileImageFromJson(json),
      description: json['description'] as String?,
    );
  }

  static int _parseId(Map<String, dynamic> json) {
    final raw = json['id'] ?? json['id_user'];
    if (raw is num) return raw.toInt();
    throw FormatException('UserSummary requires numeric id or id_user');
  }

  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : username;
  }

  UserSummary copyWith({
    int? id,
    String? username,
    double? reputation,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? description,
  }) {
    return UserSummary(
      id: id ?? this.id,
      username: username ?? this.username,
      reputation: reputation ?? this.reputation,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      description: description ?? this.description,
    );
  }
}
