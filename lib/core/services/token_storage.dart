import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps [FlutterSecureStorage] for auth token & user data persistence.
///
/// On iOS and Android the data is stored encrypted in the platform keychain /
/// Keystore-backed EncryptedSharedPreferences.
///
/// On macOS debug builds (unsigned), Keychain access is not available without
/// a signing certificate. In that case all operations silently no-op and the
/// data is kept in-memory only for the duration of the session.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  // TOKEN

  /// Persists [token] securely. Pass `null` to remove it.
  /// Silently no-ops if the platform Keychain is unavailable.
  static Future<void> write(String? token) async {
    try {
      if (token == null || token.isEmpty) {
        await _storage.delete(key: _tokenKey);
      } else {
        await _storage.write(key: _tokenKey, value: token);
      }
    } catch (e) {
      debugPrint('[TokenStorage] write failed (Keychain unavailable?): $e');
    }
  }

  /// Returns the stored token, or `null` if none exists or storage is unavailable.
  static Future<String?> read() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('[TokenStorage] read failed (Keychain unavailable?): $e');
      return null;
    }
  }

  // USER

  /// Persists the logged-in user's JSON. Pass `null` to remove it.
  static Future<void> writeUser(Map<String, dynamic>? userJson) async {
    try {
      if (userJson == null) {
        await _storage.delete(key: _userKey);
      } else {
        final encoded = jsonEncode(userJson);
        await _storage.write(key: _userKey, value: encoded);
      }
    } catch (e) {
      debugPrint('[TokenStorage] writeUser failed: $e');
    }
  }

  /// Returns the stored user JSON, or `null` if none exists.
  static Future<Map<String, dynamic>?> readUser() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw == null) {
        return null;
      }
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[TokenStorage] readUser failed: $e');
      return null;
    }
  }

  // CLEAR

  /// Removes both the stored token and user data.
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (e) {
      debugPrint('[TokenStorage] clear failed (Keychain unavailable?): $e');
    }
  }
}
