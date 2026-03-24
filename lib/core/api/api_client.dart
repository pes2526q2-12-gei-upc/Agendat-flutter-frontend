import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static const Duration timeout = Duration(seconds: 12);

  static const Map<String, String> _baseHeaders = {
    'Accept': 'application/json',
  };

  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = (token == null || token.trim().isEmpty) ? null : token.trim();
  }

  static Map<String, String> _headers({bool jsonContentType = false}) {
    final headers = <String, String>{..._baseHeaders};
    if (jsonContentType) {
      headers['Content-Type'] = 'application/json';
    }
    final token = _authToken;
    if (token != null) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  static String get baseUrl {
    const customBaseUrl = String.fromEnvironment('API_BASE_URL');
    if (customBaseUrl.isNotEmpty) return customBaseUrl;
    if (kIsWeb) return 'http://localhost:8080';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? queryParams
          : null,
    );

    final response = await http.get(uri, headers: _headers()).timeout(timeout);

    if (response.statusCode != 200) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }

    return response;
  }

  static Future<http.Response> postJson(
    String path, {
    Map<String, String>? queryParams,
    Object? body,
    int expectedStatusCode = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? queryParams
          : null,
    );

    final response = await http
        .post(
          uri,
          headers: _headers(jsonContentType: true),
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (response.statusCode != expectedStatusCode) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }

    return response;
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParams,
    int expectedStatusCode = 204,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? queryParams
          : null,
    );

    final response = await http
        .delete(uri, headers: _headers())
        .timeout(timeout);

    if (response.statusCode != expectedStatusCode) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }

    return response;
  }

  static dynamic decodeBody(http.Response response) =>
      jsonDecode(response.body);

  /// Handles the multiple list response formats the events API can return.
  static List<Map<String, dynamic>> decodeListBody(http.Response response) {
    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.whereType<Map<String, dynamic>>().toList();
    }
    if (decoded is Map<String, dynamic>) {
      final list = decoded['results'] ?? decoded['events'];
      if (list is List) {
        return list.whereType<Map<String, dynamic>>().toList();
      }
    }
    throw const FormatException('Unexpected API response format');
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  final Uri uri;

  const ApiException(this.statusCode, this.body, this.uri);

  @override
  String toString() => 'ApiException(HTTP $statusCode) for $uri — $body';
}
