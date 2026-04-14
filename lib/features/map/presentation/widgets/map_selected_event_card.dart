import 'package:flutter/material.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';

class MapSelectedEventCard extends StatelessWidget {
  const MapSelectedEventCard({
    required this.event,
    required this.hasCurrentLocation,
    required this.distanceKm,
    required this.cardHeight,
    required this.onRoutePressed,
    required this.onMoreDetailsPressed,
    required this.onClosePressed,
    super.key,
  });

  final MapEventMarkerData event;
  final bool hasCurrentLocation;
  final double distanceKm;
  final double cardHeight;
  final VoidCallback onRoutePressed;
  final VoidCallback onMoreDetailsPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: cardHeight,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                event.startDateLabel == event.endDateLabel
                    ? event.startDateLabel
                    : '${event.startDateLabel} - ${event.endDateLabel}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (hasCurrentLocation) ...[
                const SizedBox(height: 2),
                Text(
                  // Si tenim GPS, ensenya km des de la ubi de l'usuari.
                  '${distanceKm.toStringAsFixed(1)} km des de la teva ubicacio',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRoutePressed,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Veure ruta'),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onMoreDetailsPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B1E1E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(38),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Veure detalls'),
                ),
              ),
            ],
          ),
          Positioned(
            top: -8,
            right: -8,
            child: IconButton(
              // Creu per tancar la targeta
              onPressed: onClosePressed,
              icon: const Icon(Icons.close),
              splashRadius: 18,
              constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
              padding: const EdgeInsets.all(4),
            ),
          ),
        ],
      ),
    );
  }
}
