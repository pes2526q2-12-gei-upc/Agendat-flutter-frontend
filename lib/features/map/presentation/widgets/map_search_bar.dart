import 'package:flutter/material.dart';

/// Barra de cerca d'esdeveniments que es mostra sobre el mapa.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    this.onChanged,
    this.margin = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  });

  /// Callback opcional per capturar text de cerca quan s'implementi la llogica.
  final ValueChanged<String>? onChanged;

  /// Marge configurable per poder reutilitzar la barra en diferents layouts.
  final EdgeInsetsGeometry margin;

  static const double _radius = 10.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade100,
            spreadRadius: 5,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: 'Cerca esdeveniments...',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}
