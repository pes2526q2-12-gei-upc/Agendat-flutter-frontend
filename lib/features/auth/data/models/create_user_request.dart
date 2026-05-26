/// Dades per crear un usuari (POST /api/users/).
/// Obligatoris: [username], [email], [password], [firstName].
class CreateUserRequest {
  CreateUserRequest({
    required this.username,
    required this.email,
    required this.password,
    required this.first_name,
    /*
    this.last_name,
    this.phone,
    this.birth_date,
    this.profile_image,
    this.location_allowed,
    this.notifications_allowed,
    this.description,
    */
  });

  final String username;
  final String email;
  final String password;
  final String first_name;
  /*
  final String? last_name;
  final String? phone;
  final String? birth_date; // ISO 8601, e.g. "2026-03-09"
  final String? profile_image;
  final bool? location_allowed;
  final bool? notifications_allowed;
  final String? description;
  */

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'username': username,
      'first_name': first_name,
      'email': email,
      'password': password,
    };
    /*
    codi que de moment no fa falta per crear l'usuari:
    if (last_name != null) map['last_name'] = last_name;
    if (phone != null) map['phone'] = phone;
    if (birthDate != null) map['birth_date'] = birthDate;
    if (profileImage != null) map['profile_image'] = profileImage;
    if (locationAllowed != null) map['location_allowed'] = locationAllowed;
    if (notificationsAllowed != null) {
      map['notifications_allowed'] = notificationsAllowed;
    }
    if (description != null) map['description'] = description;*/
    return map;
  }
}
