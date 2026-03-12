import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class MapNavigationService {
  Future<bool> openNavigation({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    final uri = isIOS
        ? Uri.parse(
            'https://maps.apple.com/?'
            'saddr=${origin.latitude},${origin.longitude}'
            '&daddr=${destination.latitude},${destination.longitude}'
            '&dirflg=d',
          )
        : Uri.parse(
            'https://www.google.com/maps/dir/?api=1'
            '&origin=${origin.latitude},${origin.longitude}'
            '&destination=${destination.latitude},${destination.longitude}'
            '&travelmode=driving',
          );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
