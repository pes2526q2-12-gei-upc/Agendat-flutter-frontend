import 'package:agendat/core/services/baseURL_api.dart';

const _defaultAwsRegion = String.fromEnvironment(
  'AWS_REGION',
  defaultValue: 'eu-south-2',
);

/// URL absoluta per mostrar una imatge de perfil (relativa al servidor o S3).
String? resolveProfileImageUrl(String? rawValue) {
  final value = rawValue?.trim();
  if (value == null || value.isEmpty) return null;

  if (value.startsWith('http://') || value.startsWith('https://')) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.host.contains('amazonaws.com')) return value;

    return _normalizeS3Url(uri) ?? value;
  }

  final baseUrl = getBaseUrl();
  final normalized = value.startsWith('/') ? value.substring(1) : value;
  if (normalized.startsWith('media/')) return '$baseUrl/$normalized';
  if (!normalized.contains('/')) return '$baseUrl/media/$normalized';
  return '$baseUrl/$normalized';
}

String? _normalizeS3Url(Uri uri) {
  final host = uri.host;
  final key = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  if (key.isEmpty) return null;

  final pathStyleMatch = RegExp(
    r'^s3[.-]([a-z0-9-]+)\.amazonaws\.com$',
    caseSensitive: false,
  ).firstMatch(host);
  if (pathStyleMatch != null) {
    return uri.toString();
  }

  final virtualHostMatch = RegExp(
    r'^(.+)\.s3[.-]([a-z0-9-]+)\.amazonaws\.com$',
    caseSensitive: false,
  ).firstMatch(host);
  if (virtualHostMatch == null) return uri.toString();

  final bucket = virtualHostMatch.group(1);
  final region = virtualHostMatch.group(2) ?? _defaultAwsRegion;
  if (bucket == null || bucket.isEmpty) return uri.toString();

  return Uri(
    scheme: 'https',
    host: 's3.$region.amazonaws.com',
    path: '/$bucket/$key',
    query: uri.hasQuery ? uri.query : null,
  ).toString();
}
