import 'package:flutter/foundation.dart';

class GoogleAuthConfig {
  GoogleAuthConfig._();

  static const webClientId =
      '29793043137-s3mq68vdm6r3o2nm9g5am1jgrtl303ou.apps.googleusercontent.com';

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static String? get clientId => _isAndroid ? null : webClientId;

  static String? get serverClientId => _isAndroid ? webClientId : null;
}
