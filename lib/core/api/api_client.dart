import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

    const useAdbReverse = bool.fromEnvironment('USE_ADB_REVERSE');
    if (useAdbReverse) return 'http://127.0.0.1:8080';

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
    Set<int>? acceptedStatusCodes,
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

    _ensureStatus(response, uri, expectedStatusCode, acceptedStatusCodes);
    return response;
  }

  static Future<http.Response> patchJson(
    String path, {
    Map<String, String>? queryParams,
    Object? body,
    int expectedStatusCode = 200,
    Set<int>? acceptedStatusCodes,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? queryParams
          : null,
    );

    final response = await http
        .patch(
          uri,
          headers: _headers(jsonContentType: true),
          body: jsonEncode(body),
        )
        .timeout(timeout);

    _ensureStatus(response, uri, expectedStatusCode, acceptedStatusCodes);
    return response;
  }

  static void _ensureStatus(
    http.Response response,
    Uri uri,
    int expectedStatusCode,
    Set<int>? acceptedStatusCodes,
  ) {
    final ok = acceptedStatusCodes != null
        ? acceptedStatusCodes.contains(response.statusCode)
        : response.statusCode == expectedStatusCode;
    if (!ok) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }
  }

  static Future<http.Response> patchMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    int expectedStatusCode = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PATCH', uri);
    request.headers.addAll(_headers());
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != expectedStatusCode) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }

    return response;
  }

  static Future<http.Response> postMultipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    int expectedStatusCode = 200,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers());
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (files != null && files.isNotEmpty) {
      request.files.addAll(files);
    }

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != expectedStatusCode) {
      final snippet = response.body.length > 200
          ? '${response.body.substring(0, 200)}...'
          : response.body;
      throw ApiException(response.statusCode, snippet, uri);
    }

    return response;
  }

  static http.MultipartFile multipartFileFromBytes({
    required String field,
    required List<int> bytes,
    required String filename,
    String contentType = 'image/jpeg',
  }) {
    final parts = contentType.split('/');
    final mediaType = parts.length == 2
        ? MediaType(parts[0], parts[1])
        : MediaType('application', 'octet-stream');
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: mediaType,
    );
  }

  static Future<http.Response> delete(
    String path, {
    Map<String, String>? queryParams,
    int expectedStatusCode = 204,
    Set<int>? acceptedStatusCodes,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParams != null && queryParams.isNotEmpty
          ? queryParams
          : null,
    );

    final response = await http
        .delete(uri, headers: _headers())
        .timeout(timeout);

    _ensureStatus(response, uri, expectedStatusCode, acceptedStatusCodes);
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
