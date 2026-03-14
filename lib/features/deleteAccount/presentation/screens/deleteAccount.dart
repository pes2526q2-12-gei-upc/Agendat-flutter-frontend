import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, this.isAuthenticated = true});

  final bool isAuthenticated;

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _isDeleting = false;

  Future<void> _requestDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirma'),
          content: const Text(
            'Estàs segur/a que vols eliminar el teu compte? Aquesta acció no es pot desfer.',
          ),
          actions: [
            TextButton(
              onPressed: () => _errorDeletingAccount(), //provisional
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acció cancelada. El compte no s\'ha eliminat.'),
        ),
      );
      return;
    }

    // Bloquegem el botó mentre fem l'acció.
    setState(() => _isDeleting = true);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte eliminat correctament. Sessió tancada.'),
      ),
    );

    // Després d'eliminar es posa la login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /*
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error al eliminar el compte'),
      ),
      body: const Center(
        child: Text(
          'S\'ha produït un error en eliminar el compte. Si us plau, torna-ho a intentar més tard.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
  */

  Future<void> _errorDeletingAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Error en eliminar el compte'),
          content: const Text(
            'S\'ha produït un error en eliminar el compte. Si us plau, torna-ho a intentar més tard.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acció cancelada. El compte no s\'ha eliminat.'),
        ),
      );
      return;
    }

    // Bloquegem el botó mentre fem l'acció.
    setState(() => _isDeleting = true);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Compte eliminat correctament. Sessió tancada.'),
      ),
    );

    // Després d'eliminar es posa la login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eliminar compte')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Si elimines el teu compte, s\'esborraran les teves dades personals i es tancarà la sessió.',
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _isDeleting ? null : _requestDeleteAccount,
              child: _isDeleting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Eliminar el meu compte'),
            ),
          ],
        ),
      ),
    );
  }
}
