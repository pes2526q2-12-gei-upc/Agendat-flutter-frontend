import 'package:flutter/material.dart';
import 'package:agendat/core/models/event.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';

class MapSelectedEventCard extends StatelessWidget {
  static const double _kStaticCardHeight = 210;

  const MapSelectedEventCard({
    required this.event,
    required this.hasCurrentLocation,
    required this.distanceKm,
    required this.onRoutePressed,
    required this.onMoreDetailsPressed,
    required this.onClosePressed,
    this.detail,
    this.isLoading = false,
    super.key,
  });

  /// Dades bàsiques del marcador (sempre en català, surt del llistat de la
  /// home). Es fa servir com a fallback fins que arriba el detall traduït.
  final MapEventMarkerData event;

  /// Detall traduït retornat per `/api/events/{code}/`. Mentre és `null`
  /// es mostren els valors d'[event] (o l'esquelet si [isLoading]).
  final EventExtended? detail;

  /// `true` mentre s'està carregant el detall i encara no hi ha resposta.
  final bool isLoading;

  final bool hasCurrentLocation;
  final double distanceKm;
  final VoidCallback onRoutePressed;
  final VoidCallback onMoreDetailsPressed;
  final VoidCallback onClosePressed;

  String get _displayTitle {
    final fromDetail = detail?.title.trim();
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;
    return event.title;
  }

  String get _displayDateRange {
    final fromDetail = detail?.displayDateRange;
    if (fromDetail != null && fromDetail.isNotEmpty) return fromDetail;
    return event.startDateLabel == event.endDateLabel
        ? event.startDateLabel
        : '${event.startDateLabel} - ${event.endDateLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final showSkeleton = isLoading && detail == null;
    final buttonsEnabled = !showSkeleton;

    return Container(
      height: _kStaticCardHeight,
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
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                if (showSkeleton) ...[
                  _skeletonLine(width: double.infinity, height: 18),
                  const SizedBox(height: 6),
                  _skeletonLine(width: 160, height: 14),
                ] else ...[
                  Text(
                    _displayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _displayDateRange,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
                    onPressed: buttonsEnabled ? onRoutePressed : null,
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
                    onPressed: buttonsEnabled ? onMoreDetailsPressed : null,
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
          ),
          Positioned(
            top: -12,
            right: -12,
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

  Widget _skeletonLine({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
