import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:agendat/features/auth/data/models/login_user_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/main.dart';
import 'package:agendat/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:agendat/features/auth/presentation/screens/sign_up.dart';
import 'package:agendat/core/utils/event_text_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _signUpTapRecognizer;

  @override
  void initState() {
    super.initState();
    _signUpTapRecognizer = TapGestureRecognizer()
      ..onTap = () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
        );
      };
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _signUpTapRecognizer.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showSnackBar('Introdueix el teu nom d\'usuari.');
      return;
    }
    if (password.isEmpty) {
      _showSnackBar('Introdueix la contrasenya.');
      return;
    }

    final result = await loginUser(
      LoginUserRequest(username: username, password: password),
    );
    if (!mounted) return;
    switch (result) {
      case LoginUserSuccess():
        // loginUser() ja ha guardat l'usuari + token
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const RootNavigationScreen(initialIndex: 0),
          ),
        );
      case LoginUserFailure(:final statusCode, :final body):
        String message = 'No s\'ha pogut iniciar sessió.';
        if (statusCode == 404) {
          message =
              'El backend no ha trobat l\'endpoint de login (/api/users/login/).';
        } else if (body != null) {
          if (body['detail'] != null) {
            message = body['detail'].toString();
          } else if (body['non_field_errors'] != null) {
            message = (body['non_field_errors'] is List)
                ? (body['non_field_errors'] as List).join(' ')
                : body['non_field_errors'].toString();
          } else if (body['username'] != null) {
            message = (body['username'] is List)
                ? (body['username'] as List).join(' ')
                : body['username'].toString();
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

  Future<void> _loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      clientId:
          '482718948827-mbcnthq46p3g8lalmehdsmmcdbtt991h.apps.googleusercontent.com',
    );

    try {
      final account = await googleSignIn.signIn();
      if (account == null) {
        // User cancelled the sign-in
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      // Web doesn't provide idToken, so we use accessToken as fallback
      if (idToken == null && accessToken == null) {
        _showSnackBar('No s\'ha pogut obtenir el token de Google.');
        return;
      }

      final result = await loginWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );
      if (!mounted) return;

      switch (result) {
        case LoginUserSuccess():
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const RootNavigationScreen(initialIndex: 0),
            ),
          );
        case LoginUserFailure(:final statusCode, :final body):
          String message = 'No s\'ha pogut iniciar sessió amb Google.';
          if (body != null && body['detail'] != null) {
            message = body['detail'].toString();
          } else if (statusCode == -1) {
            message = 'Error de connexió. Comprova la xarxa.';
          }
          _showSnackBar(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error durant el login amb Google: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * (1 / 3);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Column(
        children: [
          // HEADER: blured red background + Casa Batlló image with calendar icon
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _CalendarIcon(),
                      const SizedBox(height: 12),
                      const Text(
                        'Agenda\'t',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cultura catalana al teu abast',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ----- FORM: scrollable white area -----
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24 + padding.top * 0.5,
                24,
                24 + padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Benvingut/da!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inicia sessió per continuar',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Nom d\'usuari',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'El teu nom d\'usuari',
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: EventTextUtils.kPrimaryRed,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Contrasenya',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'La teva contrasenya',
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
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: EventTextUtils.kPrimaryRed,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey.shade600,
                          size: 22,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () {
                      _login();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: EventTextUtils.kPrimaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Text('Inicia sessió'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o continua amb',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _GoogleGIcon(),
                    label: const Text('Continua amb Google'),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'He oblidat la meva contrasenya',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: EventTextUtils.kPrimaryRed,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          const TextSpan(text: 'Encara no tens compte? '),
                          TextSpan(
                            text: 'Registra\'t',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: EventTextUtils.kPrimaryRed,
                            ),
                            recognizer: _signUpTapRecognizer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small calendar-style icon with "JUL 17" for the header.
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

/// Simple "G" style icon for Google button (no official logo asset).
class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }
}
