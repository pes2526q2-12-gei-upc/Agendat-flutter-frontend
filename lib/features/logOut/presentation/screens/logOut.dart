import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

//PENDENT: esborrar el token d'autenticació

class LogOutScreen extends StatefulWidget {
  const LogOutScreen({super.key});

  @override
  State<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends State<LogOutScreen> {
  bool _isLoggingOut = false;

  Future<void> _clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<void> _requestLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirma'),
          content: const Text('Estàs segur/a que vols tancar la sessió?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Tancar sessió'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await _clearAuthToken();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No s\'ha pogut tancar la sessio.')),
        );
        setState(() => _isLoggingOut = false);
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tancar sessió')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Si tanques la sessió, hauràs d\'iniciar sessió de nou per accedir a l\'aplicació.',
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _isLoggingOut ? null : _requestLogOut,
              child: _isLoggingOut
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tancar sessió'),
            ),
          ],
        ),
      ),
    );
  }
}
