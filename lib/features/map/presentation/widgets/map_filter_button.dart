import 'package:flutter/material.dart';

class MapFilterButton extends StatelessWidget {
  const MapFilterButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // PENDENT: No fa res de moment
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
