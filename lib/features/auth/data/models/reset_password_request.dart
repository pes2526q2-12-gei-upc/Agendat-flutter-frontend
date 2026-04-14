/// Cos de POST /api/users/password-reset/confirm/
class ResetPasswordRequest {
  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  final String email;
  final String code;
  final String newPassword;

  Map<String, dynamic> toJson() => {
    'email': email,
    'code': code,
    'new_password': newPassword,
  };
}
