import 'package:flutter/material.dart';

/// Targeta blanca que serveix com a contenidor d'informació (p. ex. "Descripció", "Informació de
/// l'esdeveniment", "Enllaços d'interès" dins la vista de detall d'un event).
///
/// El paràmetre [trailing] permet posar un widget a la dreta del títol
/// (típicament una icona per expandir/col·lapsar el contingut).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.content,
    this.trailing,
  });

  final String title;
  final Widget content;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 202, 3, 3),
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
