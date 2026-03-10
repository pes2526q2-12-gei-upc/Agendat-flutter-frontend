/// Dades per crear un usuari (POST /api/users/).
/// Obligatoris: [username], [email].
class CreateUserRequest {
  CreateUserRequest({
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.birthDate,
    this.profileImage,
    this.locationAllowed,
    this.notificationsAllowed,
    this.description,
    this.password,
  });

  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? birthDate; // ISO 8601, e.g. "2026-03-09"
  final String? profileImage;
  final bool? locationAllowed;
  final bool? notificationsAllowed;
  final String? description;
  final String? password;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'username': username, 'email': email};
    if (firstName != null) map['first_name'] = firstName;
    if (lastName != null) map['last_name'] = lastName;
    if (phone != null) map['phone'] = phone;
    if (birthDate != null) map['birth_date'] = birthDate;
    if (profileImage != null) map['profile_image'] = profileImage;
    if (locationAllowed != null) map['location_allowed'] = locationAllowed;
    if (notificationsAllowed != null) {
      map['notifications_allowed'] = notificationsAllowed;
    }
    if (description != null) map['description'] = description;
    if (password != null && password!.isNotEmpty) map['password'] = password;
    return map;
  }
}
