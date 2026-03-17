import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.onChanged,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final ValueChanged<String>? onChanged;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SearchBar(
        onChanged: onChanged,
        hintText: 'Cerca esdeveniments...',
        leading: const Icon(Icons.search),
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(5),
        shadowColor: const WidgetStatePropertyAll(
          Color.fromARGB(255, 204, 117, 126),
        ),
      ),
    );
  }
}
