import 'package:flutter/foundation.dart';

String getBaseUrl() {
  const customBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (customBaseUrl.isNotEmpty) return customBaseUrl;

  if (kIsWeb) return 'http://localhost:8000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://localhost:8000';
}
