import 'package:agendat/core/services/baseURL_api.dart';

const _defaultAwsBucketName = String.fromEnvironment(
  'AWS_STORAGE_BUCKET_NAME',
  defaultValue: 'agendat.s3',
);
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

    final normalizedPath = uri.path.startsWith('/$_defaultAwsBucketName/')
        ? uri.path.substring(_defaultAwsBucketName.length + 2)
        : uri.path.startsWith('/')
        ? uri.path.substring(1)
        : uri.path;

    return Uri(
      scheme: 'https',
      host: 's3.$_defaultAwsRegion.amazonaws.com',
      path: '/$_defaultAwsBucketName/$normalizedPath',
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }

  final baseUrl = getBaseUrl();
  final normalized = value.startsWith('/') ? value.substring(1) : value;
  if (normalized.startsWith('media/')) return '$baseUrl/$normalized';
  if (!normalized.contains('/')) return '$baseUrl/media/$normalized';
  return '$baseUrl/$normalized';
}
