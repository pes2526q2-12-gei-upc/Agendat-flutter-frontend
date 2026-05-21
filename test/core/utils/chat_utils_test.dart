import 'package:agendat/core/utils/chat_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('chatDisplayDateTime', () {
    test('converts UTC chat timestamps to local time', () {
      final utc = DateTime.utc(2026, 5, 14, 10, 0);

      expect(chatDisplayDateTime(utc), utc.toLocal());
    });

    test('leaves already-local timestamps unchanged', () {
      final local = DateTime(2026, 5, 14, 12, 0);

      expect(chatDisplayDateTime(local), local);
    });
  });
}
