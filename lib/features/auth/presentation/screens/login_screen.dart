import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:agendat/features/auth/data/models/login_user_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/main.dart';
import 'package:agendat/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:agendat/features/auth/presentation/screens/register_interests_screen.dart';
import 'package:agendat/features/auth/presentation/screens/sign_up.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
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
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
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
        // loginUser() ja ha guardat l'usuari + token. Inicialitzem les
        // caches de sessió (usuaris bloquejats, etc.) abans de navegar
        // perquè la primera pantalla autenticada ja vegi l'estat correcte.
        await _enterHome();
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

  /// Repobla les caches que depenen de l'usuari autenticat (usuaris
  /// bloquejats, set local d'amistats eliminades, etc.) abans d'entrar a la
  /// pantalla principal. Així evitem que un usuari que abans havia bloquejat
  /// algú no l'identifiqui com a bloquejat just després d'iniciar sessió,
  /// i veiem el botó correcte de "Desbloquejar" en comptes d'oferir-li
  /// enviar una sol·licitud d'amistat. La crida ja gestiona internament
  /// els errors de xarxa, així que mai bloqueja el flux d'inici de sessió.
  Future<void> _bootstrapSessionCaches() async {
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      await ProfileQuery.instance.bootstrapForAuthenticatedUser(myId);
    }
  }

  // funcio default
  Future<void> _enterHome() async {
    await _bootstrapSessionCaches();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const RootNavigationScreen(initialIndex: 0),
      ),
    );
  }

  // interessos setup (desde login google) -> Home screen
  Future<void> _enterHomeAfterGoogleOnboarding(NavigatorState navigator) async {
    await _bootstrapSessionCaches();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RootNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  // Login amb google -> interessos setup
  void _openGoogleInterestOnboarding(int userId) {
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => RegisterInterestsScreen(
          userId: userId,
          onFinished: () {
            _enterHomeAfterGoogleOnboarding(navigator);
          },
        ),
      ),
    );
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
    _login();
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
        case LoginUserSuccess(:final body):
          // Mateix tractament que el login per credencials: prepara les
          // caches dependents de la sessió abans d'entrar a la home.
          final userId = _userIdFromLoginBody(body);
          if (_isNewUserFromLoginBody(body) && userId != null) {
            _openGoogleInterestOnboarding(userId);
            return;
          }

          await _enterHome();
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

  bool _isNewUserFromLoginBody(Map<String, dynamic>? body) {
    return body?['is_new_user'] == true;
  }

  int? _userIdFromLoginBody(Map<String, dynamic>? body) {
    final user = body?['user'];
    if (user is Map<String, dynamic>) {
      final id = user['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    }

    final currentId = currentLoggedInUser?['id'];
    if (currentId is int) return currentId;
    if (currentId is num) return currentId.toInt();

    return null;
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
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/icons/logoAgendat.png',
                            height: 120,
                          ),
                        ),
                      ),
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
                AppScreenSpacing.horizontal,
                24 + padding.top * 0.5,
                AppScreenSpacing.horizontal,
                AppScreenSpacing.bottom + padding.bottom,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    },
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitWithKeyboard(),
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
                      _submitWithKeyboard();
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
                        Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text('Inicia sessió'),
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
                        style: TextStyle(
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
