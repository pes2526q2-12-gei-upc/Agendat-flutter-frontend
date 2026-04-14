import 'package:flutter/material.dart';

import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/auth/data/models/forgot_password_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/reset_password_screen.dart';

/// Pantalla 1 del flux: l'usuari introdueix el **correu** associat al compte.
///
/// Es fa `POST /api/users/password-reset/` amb `{ "email": "..." }`.
/// Si el backend respon 200, s'envia un codi de 6 dígits al correu i passem
/// a [ResetPasswordScreen] per introduir codi + nova contrasenya.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? null : Colors.green.shade700,
      ),
    );
  }

  String _messageForFailure(ForgotPasswordFailure f) {
    if (f.statusCode == -1) {
      return 'Error de connexió. Comprova la xarxa.';
    }
    final body = f.body;
    if (body == null) {
      return 'No s\'ha pogut processar la sol·licitud.';
    }
    if (body['detail'] != null) {
      return body['detail'].toString();
    }
    if (body['email'] != null) {
      final e = body['email'];
      return e is List ? e.join(' ') : e.toString();
    }
    return 'No s\'ha pogut enviar la sol·licitud.';
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Introdueix el correu electrònic.');
      return;
    }
    if (!email.contains('@')) {
      _showSnackBar('Introdueix un correu electrònic vàlid.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await forgotPassword(ForgotPasswordRequest(email: email));
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ForgotPasswordSuccess():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)),
        );
      case final ForgotPasswordFailure f:
        _showSnackBar(_messageForFailure(f));
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: EventTextUtils.kPrimaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Contrasenya oblidada'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recupera l\'accés',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escriu el correu del teu compte. T\'enviarem un codi de 6 dígits.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            Text(
              'Correu electrònic',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'exemple@correu.cat',
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
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
