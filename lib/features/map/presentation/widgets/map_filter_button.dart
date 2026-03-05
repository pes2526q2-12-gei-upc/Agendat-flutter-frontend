import 'package:flutter/material.dart';

/// Boto de filtre per a futurs tipus de filtratge d'esdeveniments.
/// Ara mateix es deixa no funcional perque encara no hi ha els filtres implementats.
class MapFilterButton extends StatelessWidget {
  const MapFilterButton({super.key, this.onPressed});

  /// Callback opcional; per defecte es mantindra desactivat.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Si encara no hi ha funcionalitat, no fa res pero es veu actiu.
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 149, 31, 22),
      ),
      icon: const Icon(Icons.filter_alt_outlined),
      label: const Text('Filtrar'),
    );
  }
}
