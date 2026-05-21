import 'package:agendat/features/chat/presentation/widgets/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message receipt label', () {
    testWidgets('renders no receipt by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Message(
              messageText: 'Hola',
              sentAt: DateTime(2026, 5, 14, 10, 0),
              isSentByMe: true,
              avatarLabel: 'Jo',
            ),
          ),
        ),
      );

      expect(find.text('Enviat'), findsNothing);
      expect(find.text('Llegit'), findsNothing);
    });

    testWidgets('renders a receipt label when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Message(
              messageText: 'Hola',
              sentAt: DateTime(2026, 5, 14, 10, 0),
              isSentByMe: true,
              avatarLabel: 'Jo',
              receiptLabel: 'Llegit',
            ),
          ),
        ),
      );

      expect(find.text('Llegit'), findsOneWidget);
    });

    testWidgets('renders image messages from fileUrl', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Message(
              messageText: '',
              messageType: 'image',
              fileUrl: 'https://example.com/photo.jpg',
              sentAt: DateTime(2026, 5, 14, 10, 0),
              isSentByMe: false,
              avatarLabel: 'Aina',
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<NetworkImage>());
      expect((image.image as NetworkImage).url, 'https://example.com/photo.jpg');
      expect(find.text('(sense text)'), findsNothing);
    });
  });
}
