import 'package:flutter/foundation.dart';

String getBaseUrl() {
  const customBaseUrl = String.fromEnvironment('API_BASE_URL');
  if (customBaseUrl.isNotEmpty) return customBaseUrl;

  const useAdbReverse = bool.fromEnvironment('USE_ADB_REVERSE');
  if (useAdbReverse) return 'http://127.0.0.1:8080';

  if (kIsWeb) return 'http://localhost:8080';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}
