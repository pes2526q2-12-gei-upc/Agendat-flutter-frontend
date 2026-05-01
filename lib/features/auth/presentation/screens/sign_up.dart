import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:agendat/features/auth/data/models/create_user_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/auth/presentation/screens/signup_code_screen.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';

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

  Future<void> _submitSignUp() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final fullName = _nameController.text.trim();

    if (username.isEmpty) {
      _showSnackBar('Introdueix un nom d\'usuari.');
      return;
    }
    if (email.isEmpty) {
      _showSnackBar('Introdueix el correu electrònic.');
      return;
    }
    if (password.length < 8) {
      _showSnackBar('La contrasenya ha de tenir almenys 8 caràcters.');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Les contrasenyes no coincideixen.');
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
        String message = 'No s\'ha pogut enviar el codi de verificació.';
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
          message = 'Error de connexió. Comprova la xarxa.';
        }
        _showSnackBar(message);
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? null : Colors.green.shade700,
      ),
    );
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
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Enrere',
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
                              const Text(
                                'Crea el teu compte',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Uneix-te a Agenda\'t',
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
                  _buildLabel('Nom d\'usuari'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    hintText: 'Nom d\'usuari únic',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_nameFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Nom complet'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    hintText: 'El teu nom',
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_emailFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Correu electrònic'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    hintText: 'exemple@correu.cat',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel('Contrasenya'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    hintText: 'Mínim 8 caràcters',
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
                  const SizedBox(height: 20),
                  _buildLabel('Confirma la contrasenya'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    hintText: 'Repeteix la contrasenya',
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
                    onPressed: _isLoading ? null : _submitWithKeyboard,
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
                        Text(_isLoading ? 'Creant compte...' : 'Crear compte'),
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
                          const TextSpan(text: 'Ja tens compte? '),
                          TextSpan(
                            text: 'Inicia sessió',
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
                      children: const [
                        TextSpan(text: 'En registrar-te acceptes els '),
                        TextSpan(
                          text: 'Termes d\'ús',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(text: ' i la '),
                        TextSpan(
                          text: 'Política de privacitat.',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
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
