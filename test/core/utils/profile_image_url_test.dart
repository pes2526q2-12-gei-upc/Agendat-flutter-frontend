import 'package:agendat/core/utils/profile_image_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveProfileImageUrl', () {
    test('keeps path-style S3 URLs with their original bucket', () {
      const url =
          'https://s3.eu-south-2.amazonaws.com/agendat-images-pes-2026/chat.png';

      expect(resolveProfileImageUrl(url), url);
    });

    test('normalizes virtual-host S3 URLs using the URL bucket', () {
      const url =
          'https://agendat-images-pes-2026.s3.eu-south-2.amazonaws.com/chat.png';

      expect(
        resolveProfileImageUrl(url),
        'https://s3.eu-south-2.amazonaws.com/agendat-images-pes-2026/chat.png',
      );
    });
  });
}
