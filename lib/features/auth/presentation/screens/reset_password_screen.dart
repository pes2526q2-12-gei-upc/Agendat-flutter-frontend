import 'package:flutter/material.dart';

import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/auth/data/models/reset_password_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';

/// Pantalla 2 del flux: rep [email] i envia codi + nova contrasenya
/// amb `POST /api/users/password-reset/confirm/`.
///
/// El cos és `{ "email", "code", "new_password" }`.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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

  String _messageForFailure(ResetPasswordFailure f) {
    if (f.statusCode == -1) {
      return 'Error de connexió. Comprova la xarxa.';
    }
    final body = f.body;
    if (body == null) {
      return 'No s\'ha pogut restablir la contrasenya.';
    }
    if (body['detail'] != null) {
      return body['detail'].toString();
    }
    if (body['new_password'] != null) {
      final p = body['new_password'];
      return p is List ? p.join(' ') : p.toString();
    }
    if (body['code'] != null) {
      final c = body['code'];
      return c is List ? c.join(' ') : c.toString();
    }
    return 'No s\'ha pogut restablir la contrasenya.';
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (code.isEmpty) {
      _showSnackBar('Introdueix el codi de 6 dígits.');
      return;
    }
    if (code.length != 6) {
      _showSnackBar('El codi ha de tenir 6 dígits.');
      return;
    }
    if (password.length < 4) {
      _showSnackBar('La contrasenya ha de tenir almenys 4 caràcters.');
      return;
    }
    if (password != confirm) {
      _showSnackBar('Les contrasenyes no coincideixen.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await resetPassword(
      ResetPasswordRequest(
        email: widget.email,
        code: code,
        newPassword: password,
      ),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ResetPasswordSuccess():
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      case final ResetPasswordFailure f:
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
        title: const Text('Nova contrasenya'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppScreenSpacing.horizontal,
          24,
          AppScreenSpacing.horizontal,
          AppScreenSpacing.bottom + padding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tria una contrasenya nova',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Introdueix el codi que has rebut per correu i la nova contrasenya.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 28),
            Text(
              'Codi de verificació',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '6 dígits',
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
            Text(
              'Nova contrasenya',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: 'Mínim 8 caràcters',
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
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Confirma la contrasenya',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                hintText: 'Repeteix la contrasenya',
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
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
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
                  : const Text('Desar contrasenya'),
            ),
          ],
        ),
      ),
    );
  }
}
