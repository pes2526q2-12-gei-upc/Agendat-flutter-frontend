/// Representació lleugera d'un usuari per als resultats del cercador.
/// Es construeix a partir de la resposta de GET /api/users/.
class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.description,
  });

  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final String? description;

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: (json['id'] as num).toInt(),
      username: (json['username'] as String?) ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: json['profile_image'] as String?,
      description: json['description'] as String?,
    );
  }

  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : username;
  }
}
