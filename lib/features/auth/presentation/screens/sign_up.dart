import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/auth/presentation/screens/signup_code_screen.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:agendat/features/auth/utils/password_validator.dart'
    show PasswordValidationIssue, PasswordValidator;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  late final TapGestureRecognizer _loginTapRecognizer;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _usernameController,
      _nameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFormChanged);
    }
    _loginTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      };
  }

  @override
  void dispose() {
    for (final controller in [
      _usernameController,
      _nameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.removeListener(_handleFormChanged);
    }
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _loginTapRecognizer.dispose();
    super.dispose();
  }

  void _handleFormChanged() {
    if (!mounted) return;
    setState(() {});
  }

  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  bool get _showConfirmPasswordMismatch {
    return _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        !_passwordsMatch;
  }

  bool get _isFormValid {
    return _usernameController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        PasswordValidator.validate(_passwordController.text) == null &&
        _passwordsMatch;
  }

  Future<void> _submitSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final fullName = _nameController.text.trim();
    final l10n = AppLocalizations.of(context);

    if (username.isEmpty) {
      _showSnackBar(l10n.enterUsername);
      return;
    }
    if (email.isEmpty) {
      _showSnackBar(l10n.enterEmail);
      return;
    }
    final passwordError = PasswordValidator.validate(password);
    if (passwordError != null) {
      _showSnackBar(_passwordValidationMessage(l10n, passwordError));
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar(l10n.passwordsDoNotMatch);
      return;
    }

    setState(() => _isLoading = true);
    final request = CreateUserRequest(
      username: username,
      email: email,
      first_name: fullName,
      password: password,
    );
    final result = await requestSignupCode(request);
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case RequestSignupCodeSuccess():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SignupCodeScreen(email: email, username: username),
          ),
        );
      case RequestSignupCodeFailure(:final statusCode, :final body):
        String message = l10n.signupCodeSendFailed;
        if (body != null) {
          if (body['email'] != null) {
            message = (body['email'] is List)
                ? (body['email'] as List).join(' ')
                : body['email'].toString();
          } else if (body['username'] != null) {
            message = (body['username'] is List)
                ? (body['username'] as List).join(' ')
                : body['username'].toString();
          } else if (body['password'] != null) {
            message = (body['password'] is List)
                ? (body['password'] as List).join(' ')
                : body['password'].toString();
          } else if (body['detail'] != null) {
            message = body['detail'].toString();
          }
        } else if (statusCode == -1) {
          message = l10n.connectionErrorCheckYourConnection;
        }
        _showSnackBar(message);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    AppSnackBar.show(context, message, isError: isError);
  }

  void _submitWithKeyboard() {
    FocusScope.of(context).unfocus();
    _submitSignUp();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * (1 / 3);
    final padding = MediaQuery.paddingOf(context);
    final l10n = AppLocalizations.of(context);
    final passwordRequirements = [
      (
        key: 'too-short',
        isMet: PasswordValidator.hasMinLength(_passwordController.text),
        label: l10n.passwordTooShort,
      ),
      (
        key: 'uppercase',
        isMet: PasswordValidator.hasUppercase(_passwordController.text),
        label: l10n.passwordNeedsUppercase,
      ),
      (
        key: 'lowercase',
        isMet: PasswordValidator.hasLowercase(_passwordController.text),
        label: l10n.passwordNeedsLowercase,
      ),
      (
        key: 'number',
        isMet: PasswordValidator.hasNumber(_passwordController.text),
        label: l10n.passwordNeedsNumber,
      ),
      (
        key: 'special-char',
        isMet: PasswordValidator.hasSpecialChar(_passwordController.text),
        label: l10n.passwordNeedsSpecialChar,
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          // HEADER: red background with Casa Batlló image, back, progress and title
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: EventTextUtils.kPrimaryRed),
                Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/icons/Casa-Batlló.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppScreenSpacing.horizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        // Back row + progress bars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    AppLocalizations.of(context).back,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                // Active step
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Inactive step (more transparent)
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Centered calendar + title + subtitle
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _CalendarIcon(),
                              const SizedBox(height: 12),
                              Text(
                                AppLocalizations.of(
                                  context,
                                ).createYourAccountTitle,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context).joinAgendaSubtitle,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // FORM AREA
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppScreenSpacing.horizontal,
                24 + padding.top * 0.5,
                AppScreenSpacing.horizontal,
                AppScreenSpacing.bottom + padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel(AppLocalizations.of(context).usernameLabel),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    hintText: AppLocalizations.of(context).usernameUniqueHint,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_nameFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(AppLocalizations.of(context).fullNameLabel),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    hintText: AppLocalizations.of(context).nameHint,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_emailFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(AppLocalizations.of(context).emailLabel),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    hintText: AppLocalizations.of(context).emailExampleHint,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(AppLocalizations.of(context).passwordLabel),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    hintText: AppLocalizations.of(
                      context,
                    ).passwordRequirementsHint,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(
                        context,
                      ).requestFocus(_confirmPasswordFocusNode);
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final requirement in passwordRequirements) ...[
                        _PasswordRequirementRow(
                          requirementKey: requirement.key,
                          label: requirement.label,
                          isMet: requirement.isMet,
                        ),
                        const SizedBox(height: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildLabel(
                    AppLocalizations.of(context).confirmPasswordLabel,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    hintText: AppLocalizations.of(
                      context,
                    ).repeatPasswordHintAuth,
                    errorText: _showConfirmPasswordMismatch
                        ? l10n.passwordsDoNotMatch
                        : null,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitWithKeyboard(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _isLoading || !_isFormValid
                        ? null
                        : _submitWithKeyboard,
                    style: FilledButton.styleFrom(
                      backgroundColor: EventTextUtils.kPrimaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.person_add_alt_1_outlined,
                            size: 20,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoading
                              ? AppLocalizations.of(
                                  context,
                                ).createAccountLoading
                              : AppLocalizations.of(context).createAccount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${AppLocalizations.of(context).haveAccountPrompt} ',
                          ),
                          TextSpan(
                            text: AppLocalizations.of(context).signIn,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: EventTextUtils.kPrimaryRed,
                            ),
                            recognizer: _loginTapRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context).signupTermsText,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: EventTextUtils.kPrimaryRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  String _passwordValidationMessage(
    AppLocalizations l10n,
    PasswordValidationIssue issue,
  ) {
    switch (issue) {
      case PasswordValidationIssue.tooShort:
        return l10n.passwordTooShort;
      case PasswordValidationIssue.needsUppercase:
        return l10n.passwordNeedsUppercase;
      case PasswordValidationIssue.needsLowercase:
        return l10n.passwordNeedsLowercase;
      case PasswordValidationIssue.needsNumber:
        return l10n.passwordNeedsNumber;
      case PasswordValidationIssue.needsSpecialChar:
        return l10n.passwordNeedsSpecialChar;
    }
  }
}

class _PasswordRequirementRow extends StatelessWidget {
  const _PasswordRequirementRow({
    required this.requirementKey,
    required this.label,
    required this.isMet,
  });

  final String requirementKey;
  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    final color = isMet ? Colors.green.shade700 : Colors.grey.shade500;

    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          key: Key(
            'password-requirement-$requirementKey-${isMet ? 'met' : 'unmet'}',
          ),
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small calendar-style icon with month + day, same look as login.
class _CalendarIcon extends StatelessWidget {
  const _CalendarIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            EventTextUtils.calendarMonthNames[DateTime.now().month - 1],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            DateTime.now().day.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
