import 'package:flutter/material.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'zoomIn',
          mini: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 149, 31, 22),
          onPressed: onZoomIn,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'zoomOut',
          mini: true,
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 149, 31, 22),
          onPressed: onZoomOut,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}
