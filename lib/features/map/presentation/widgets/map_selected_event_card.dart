import 'package:agendat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/models/event_map.dart';
import 'package:agendat/features/map/presentation/widgets/map_event_markers.dart';

class MapSelectedEventCard extends StatelessWidget {
  /// Alçada màxima abans d'activar scroll (la card es redueix si n'hi ha menys).
  static const double _kMaxCardHeight = 280;

  const MapSelectedEventCard({
    required this.marker,
    required this.hasCurrentLocation,
    required this.distanceKm,
    required this.onRoutePressed,
    required this.onMoreDetailsPressed,
    required this.onClosePressed,
    this.preview,
    this.isLoading = false,
    super.key,
  });

  /// Identifier + coords of the tapped pin. Used as fallback while the
  /// preview is loading.
  final MapEventMarker marker;

  /// Translated preview returned by `/api/events/{code}/preview/`. Null until
  /// it arrives; the card shows the skeleton while [isLoading] is true.
  final EventPreview? preview;

  /// `true` while the preview is being fetched and there is no response yet.
  final bool isLoading;

  final bool hasCurrentLocation;
  final double distanceKm;
  final VoidCallback onRoutePressed;
  final VoidCallback onMoreDetailsPressed;
  final VoidCallback onClosePressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showSkeleton = isLoading && preview == null;
    final buttonsEnabled = !showSkeleton;

    return Container(
      constraints: const BoxConstraints(maxHeight: _kMaxCardHeight),
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
          // Padding right per no quedar sota la creueta de tancar.
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 28),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSkeleton)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _skeletonLine(width: double.infinity, height: 18),
                          const SizedBox(height: 6),
                          _skeletonLine(width: 160, height: 14),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            preview?.displayTitle ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            preview?.displayDateRange ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (hasCurrentLocation) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.distanceFromLocation(
                          distanceKm.toStringAsFixed(1),
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
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
                        child: Text(l10n.viewRoute),
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
                        child: Text(l10n.viewDetails),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              // Creu per tancar la targeta (queda dins del card per
              // no ser tallada pel ClipRRect del mapa).
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
