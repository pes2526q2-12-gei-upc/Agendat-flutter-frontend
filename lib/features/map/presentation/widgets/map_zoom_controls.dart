import 'package:flutter/material.dart';

class MapZoomControls extends StatelessWidget {
  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    this.radius = 12.0,
    this.buttonSize = 48.0,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final double radius;
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: FloatingActionButton(
            heroTag: 'zoomIn',
            backgroundColor: Colors.white,
            foregroundColor: const Color.fromARGB(255, 149, 31, 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            onPressed: onZoomIn,
            child: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: FloatingActionButton(
            heroTag: 'zoomOut',
            backgroundColor: Colors.white,
            foregroundColor: const Color.fromARGB(255, 149, 31, 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            onPressed: onZoomOut,
            child: const Icon(Icons.remove),
          ),
        ),
      ],
    );
  }
}
