import 'package:flutter_test/flutter_test.dart';

import 'package:agendat/features/profile/presentation/screens/edit_profile_screen.dart';

void main() {
  group('parseProfileFullName', () {
    test('splits a multi-part full name into first and last name fields', () {
      final parts = parseProfileFullName('Ada Maria Lovelace');

      expect(parts.firstName, 'Ada Maria');
      expect(parts.lastName, 'Lovelace');
    });

    test('uses a single entered name as first name', () {
      final parts = parseProfileFullName('Ada');

      expect(parts.firstName, 'Ada');
      expect(parts.lastName, '');
    });

    test('normalizes extra whitespace', () {
      final parts = parseProfileFullName('  Ada   Maria   Lovelace  ');

      expect(parts.firstName, 'Ada Maria');
      expect(parts.lastName, 'Lovelace');
    });
  });
}
