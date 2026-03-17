/// Dades per iniciar sessió (POST /api/users/login/).
/// Obligatoris: [username], [password].

class LoginUserRequest {
  LoginUserRequest({required this.username, required this.password});

  final String username;
  final String password;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'username': username, 'password': password};
    return map;
  }
}
