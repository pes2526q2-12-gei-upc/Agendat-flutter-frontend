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

  static PasswordValidationIssue? validate(String password) {
    if (password.length < minLength) {
      return PasswordValidationIssue.tooShort;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return PasswordValidationIssue.needsUppercase;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return PasswordValidationIssue.needsLowercase;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return PasswordValidationIssue.needsNumber;
    }
    if (!password.contains(RegExp(r'[^a-zA-Z0-9]'))) {
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
