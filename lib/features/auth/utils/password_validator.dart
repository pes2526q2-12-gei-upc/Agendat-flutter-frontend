/// Validació de contrasenya segons la política de seguretat de l'app.
class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static const String requirementsHintKey = 'passwordRequirementsHint';

  static const String passwordTooShortKey = 'passwordTooShort';
  static const String passwordNeedsUppercaseKey = 'passwordNeedsUppercase';
  static const String passwordNeedsLowercaseKey = 'passwordNeedsLowercase';
  static const String passwordNeedsNumberKey = 'passwordNeedsNumber';
  static const String passwordNeedsSpecialCharKey = 'passwordNeedsSpecialChar';

  static bool hasMinLength(String password) => password.length >= minLength;

  static bool hasUppercase(String password) =>
      password.contains(RegExp(r'[A-Z]'));

  static bool hasLowercase(String password) =>
      password.contains(RegExp(r'[a-z]'));

  static bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

  static bool hasSpecialChar(String password) =>
      password.contains(RegExp(r'[^a-zA-Z0-9]'));

  static PasswordValidationIssue? validate(String password) {
    if (!hasMinLength(password)) {
      return PasswordValidationIssue.tooShort;
    }
    if (!hasUppercase(password)) {
      return PasswordValidationIssue.needsUppercase;
    }
    if (!hasLowercase(password)) {
      return PasswordValidationIssue.needsLowercase;
    }
    if (!hasNumber(password)) {
      return PasswordValidationIssue.needsNumber;
    }
    if (!hasSpecialChar(password)) {
      return PasswordValidationIssue.needsSpecialChar;
    }
    return null;
  }
}

enum PasswordValidationIssue {
  tooShort,
  needsUppercase,
  needsLowercase,
  needsNumber,
  needsSpecialChar,
}
