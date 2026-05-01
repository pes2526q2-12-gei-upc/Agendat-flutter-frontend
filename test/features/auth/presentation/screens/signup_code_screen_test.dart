import 'package:agendat/features/auth/presentation/screens/signup_code_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignupCodeScreen(email: 'user@example.com', username: 'user'),
      ),
    );
    await tester.pump();
  }

  List<TextField> codeFields(WidgetTester tester) {
    return tester.widgetList<TextField>(find.byType(TextField)).toList();
  }

  testWidgets('shows six separate code boxes', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(TextField), findsNWidgets(6));
  });

  testWidgets('pasting a full code distributes digits across all boxes', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.pump();

    final fields = codeFields(tester);
    expect(fields.map((field) => field.controller?.text).toList(), [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
    ]);
  });
}
