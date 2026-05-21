import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agendat/core/api/api_client.dart';

/// Decodes an API error response body into a map when possible.
Map<String, dynamic>? decodeApiErrorBody(String body) {
  if (body.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {
    // Not valid JSON.
  }
  return null;
}

/// Extracts a human-readable message from a decoded API error payload.
String? extractApiErrorMessage(Object? decoded) {
  if (decoded == null) return null;

  if (decoded is String && decoded.trim().isNotEmpty) {
    return decoded.trim();
  }

  if (decoded is List && decoded.isNotEmpty) {
    return extractApiErrorMessage(decoded.first);
  }

  if (decoded is! Map<String, dynamic>) return null;

  for (final key in const ['detail', 'error', 'message']) {
    final value = decoded[key];
    final message = _messageFromValue(value);
    if (message != null) return message;
  }

  final nonFieldErrors = decoded['non_field_errors'];
  final nonFieldMessage = _messageFromValue(nonFieldErrors);
  if (nonFieldMessage != null) return nonFieldMessage;

  for (final entry in decoded.entries) {
    final message = _messageFromValue(entry.value);
    if (message != null) return message;
  }

  return null;
}

String? _messageFromValue(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is List && value.isNotEmpty) {
    return _messageFromValue(value.first);
  }
  return null;
}

/// Extracts a message directly from a raw API error body string.
String? extractApiErrorMessageFromBody(String body) {
  final decoded = decodeApiErrorBody(body);
  if (decoded != null) {
    return extractApiErrorMessage(decoded);
  }
  if (body.trim().isNotEmpty) return body.trim();
  return null;
}

/// Returns a user-facing message for an [ApiException].
String userMessageFromApiException(ApiException exception, {String? fallback}) {
  final parsed = extractApiErrorMessageFromBody(exception.body);
  if (parsed != null && parsed.isNotEmpty) return parsed;

  return _messageForStatusCode(exception.statusCode, fallback: fallback);
}

/// Returns a user-facing message for any thrown error.
String userMessageFromError(Object error, {String? fallback}) {
  if (error is ApiException) {
    return userMessageFromApiException(error, fallback: fallback);
  }

  if (_isNetworkError(error)) {
    return 'Error de connexió. Comprova la teva connexió a internet.';
  }

  return fallback ?? 'Hi ha hagut un error inesperat.';
}

bool _isNetworkError(Object error) {
  return error is TimeoutException ||
      error is SocketException ||
      error is HandshakeException ||
      error is HttpException;
}

String _messageForStatusCode(int statusCode, {String? fallback}) {
  switch (statusCode) {
    case -1:
      return 'Error de connexió. Comprova la teva connexió a internet.';
    case 401:
      return 'Cal iniciar sessió.';
    case 403:
      return 'No tens permís per fer aquesta acció.';
    case 404:
      return fallback ?? 'Recurs no trobat.';
    case 413:
      return 'El fitxer és massa gran.';
    case 500:
    case 502:
    case 503:
      return fallback ?? 'Error del servidor. Torna-ho a provar més tard.';
    default:
      if (statusCode >= 500) {
        return fallback ?? 'Error del servidor (codi $statusCode).';
      }
      if (statusCode >= 400) {
        return fallback ?? 'La sol·licitud no és vàlida (codi $statusCode).';
      }
      return fallback ?? 'Hi ha hagut un error inesperat.';
  }
}
