import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/events_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventsQuery.refreshTranslatedContent', () {
    setUp(() {
      QueryClient.instance.invalidateAll();
      EventsQuery.instance.resetTranslatedContentRevisionForTesting();
    });

    tearDown(() {
      QueryClient.instance.invalidateAll();
      EventsQuery.instance.resetTranslatedContentRevisionForTesting();
    });

    test(
      'increments the translated-content revision and rotates page keys',
      () {
        final query = EventsQuery.instance;
        final firstKey = query.debugPageKeyForTesting(
          const EventFilters(),
          0,
          EventsQuery.defaultPageSize,
        );

        query.refreshTranslatedContent();

        final secondKey = query.debugPageKeyForTesting(
          const EventFilters(),
          0,
          EventsQuery.defaultPageSize,
        );

        expect(query.translatedContentRevisionForTesting, 1);
        expect(secondKey, isNot(firstKey));
      },
    );
  });
}
