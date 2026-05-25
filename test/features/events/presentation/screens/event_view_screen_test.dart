import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/features/events/presentation/screens/event_view_screen.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const eventCode = 'event-123';

  setUp(() {
    QueryClient.instance.invalidateAll();
    EventsQuery.instance.resetTranslatedContentRevisionForTesting();
    QueryClient.instance.setQueryData<EventExtended>(
      EventsQuery.instance.debugDetailKeyForTesting(eventCode),
      EventExtended(
        code: eventCode,
        title: 'Sample event',
        description: 'Localized description body',
        free: true,
        isPrivate: true,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 2),
        schedule: '10:00 - 12:00',
        modality: 'Online',
        address: 'Main street 1',
        url_activity: 'https://example.com/activity',
      ),
    );
  });

  Future<void> pumpScreen(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EventScreen(eventCode: eventCode),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders event detail labels in English', (tester) async {
    await pumpScreen(tester, const Locale('en'));

    expect(find.text('DESCRIPTION'), findsOneWidget);
    expect(find.text('EVENT INFORMATION'), findsOneWidget);
    expect(
      find.textContaining('Date: 01/06/2026 - 02/06/2026'),
      findsOneWidget,
    );
    expect(find.textContaining('Schedule: 10:00 - 12:00'), findsOneWidget);
    expect(find.textContaining('Privacy: Private'), findsOneWidget);
    expect(find.textContaining('Price: Free'), findsOneWidget);
    expect(find.text('INTERESTING LINKS'), findsOneWidget);
    expect(find.text('Attend'), findsOneWidget);
  });
}
