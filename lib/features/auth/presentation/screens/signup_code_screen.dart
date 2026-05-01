import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/auth/data/models/signup_code_confirm_request.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/register_interests_screen.dart';
import 'package:agendat/main.dart';

class SignupCodeScreen extends StatefulWidget {
  const SignupCodeScreen({
    super.key,
    required this.email,
    required this.username,
  });

  final String email;
  final String username;

  @override
  State<SignupCodeScreen> createState() => _SignupCodeScreenState();
}

class _SignupCodeScreenState extends State<SignupCodeScreen> {
  static const int _codeLength = 6;

  final List<TextEditingController> _codeControllers = List.generate(
    _codeLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _codeFocusNodes = List.generate(
    _codeLength,
    (_) => FocusNode(),
  );
  bool _isLoading = false;

  @override
  void dispose() {
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    for (final focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
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

  String _messageForFailure(ConfirmSignupCodeFailure failure) {
    if (failure.statusCode == -1) {
      return 'Error de connexió. Comprova la xarxa.';
    }
    final body = failure.body;
    if (body == null) {
      return 'No s\'ha pogut verificar el compte.';
    }
    if (body['detail'] != null) {
      return body['detail'].toString();
    }
    if (body['code'] != null) {
      final code = body['code'];
      return code is List ? code.join(' ') : code.toString();
    }
    if (body['email'] != null) {
      final email = body['email'];
      return email is List ? email.join(' ') : email.toString();
    }
    if (body['username'] != null) {
      final username = body['username'];
      return username is List ? username.join(' ') : username.toString();
    }
    return 'No s\'ha pogut verificar el compte.';
  }

  int? _userIdFromBody(Map<String, dynamic>? body) {
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

  String get _code =>
      _codeControllers.map((controller) => controller.text).join().trim();

  void _setCodeField(int index, String value) {
    _codeControllers[index].value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleCodeChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      if (value.isNotEmpty) _setCodeField(index, '');
      return;
    }

    if (digits.length == 1) {
      if (_codeControllers[index].text != digits) {
        _setCodeField(index, digits);
      }
      if (index < _codeLength - 1) {
        _codeFocusNodes[index + 1].requestFocus();
      } else {
        _codeFocusNodes[index].unfocus();
      }
      return;
    }

    _pasteCodeDigits(startIndex: index, digits: digits);
  }

  void _pasteCodeDigits({required int startIndex, required String digits}) {
    final limitedDigits = digits
        .replaceAll(RegExp(r'\D'), '')
        .characters
        .take(_codeLength - startIndex)
        .toList();

    for (var offset = 0; offset < limitedDigits.length; offset += 1) {
      _setCodeField(startIndex + offset, limitedDigits[offset]);
    }

    final nextIndex = startIndex + limitedDigits.length;
    if (nextIndex < _codeLength) {
      _codeFocusNodes[nextIndex].requestFocus();
    } else {
      _codeFocusNodes[_codeLength - 1].unfocus();
    }
  }

  Future<void> _submit() async {
    final code = _code;
    if (code.isEmpty) {
      _showSnackBar('Introdueix el codi de 6 dígits.');
      return;
    }
    if (code.length != 6) {
      _showSnackBar('El codi ha de tenir 6 dígits.');
      return;
    }

    setState(() => _isLoading = true);
    final result = await confirmSignupCode(
      SignupCodeConfirmRequest(email: widget.email, code: code),
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result) {
      case ConfirmSignupCodeSuccess(:final body):
        final userId = _userIdFromBody(body);
        if (userId == null) {
          _enterHome();
          return;
        }
        final navigator = Navigator.of(context);
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegisterInterestsScreen(
              userId: userId,
              onFinished: () => _enterHome(navigator: navigator),
            ),
          ),
        );
      case final ConfirmSignupCodeFailure failure:
        _showSnackBar(_messageForFailure(failure));
    }
  }

  void _enterHome({NavigatorState? navigator}) {
    (navigator ?? Navigator.of(context)).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const RootNavigationScreen(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  void _submitWithKeyboard() {
    FocusScope.of(context).unfocus();
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: EventTextUtils.kPrimaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Verifica el compte'),
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
              'Revisa el teu correu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hem enviat un codi de 6 dígits a ${widget.email}. Introdueix-lo per crear el compte.',
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
            _buildCodeInput(),
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
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Crear compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_codeLength, (index) {
        return SizedBox(
          width: 46,
          height: 56,
          child: TextField(
            controller: _codeControllers[index],
            focusNode: _codeFocusNodes[index],
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            textInputAction: index == _codeLength - 1
                ? TextInputAction.done
                : TextInputAction.next,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_codeLength),
            ],
            onChanged: (value) => _handleCodeChanged(index, value),
            onSubmitted: (_) {
              if (index == _codeLength - 1) {
                _submitWithKeyboard();
              } else {
                _codeFocusNodes[index + 1].requestFocus();
              }
            },
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: EventTextUtils.kPrimaryRed,
                  width: 1.6,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        );
      }),
    );
  }
}
