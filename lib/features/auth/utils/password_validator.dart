/// Validació de contrasenya segons la política de seguretat de l'app.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  /// Text curt per mostrar com a hint sota el camp de contrasenya.
  static const String requirementsHint =
      'Mín. 8 caràcters, majúscula, minúscula, número i caràcter especial';

  /// Retorna `null` si la contrasenya és vàlida; sinó, un missatge d'error en català.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'La contrasenya ha de tenir almenys 8 caràcters.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contrasenya ha de contenir almenys una majúscula.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'La contrasenya ha de contenir almenys una minúscula.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contrasenya ha de contenir almenys un número.';
    }
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
      return 'La contrasenya ha de contenir almenys un caràcter especial.';
    }
    return null;
  }
}
