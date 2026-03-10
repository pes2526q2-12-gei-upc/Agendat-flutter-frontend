import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agendat/main.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(VisualizeScreen), findsOneWidget);
  });
}
