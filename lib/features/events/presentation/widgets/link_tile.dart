import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tile per obrir un enllaç extern al navegador.
/// isPrimary destaca enllaços importants (p.ex. compra d'entrades).
class LinkTile extends StatelessWidget {
  const LinkTile({
    super.key,
    required this.label,
    required this.uri,
    this.isPrimary = false,
  });

  final String label;
  final Uri uri;
  final bool isPrimary;

  Future<void> _openLink(BuildContext context) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No s\'ha pogut obrir l\'enllaç')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.open_in_new_rounded,
        color: isPrimary
            ? const Color.fromARGB(255, 202, 3, 3)
            : Colors.blueGrey,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isPrimary
              ? const Color.fromARGB(255, 202, 3, 3)
              : Colors.black87,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () => _openLink(context),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
