import 'package:flutter_test/flutter_test.dart';

import 'package:agendat/features/social/data/social_api.dart';

void main() {
  group('FriendRecommendationsData.fromJson', () {
    test('parses a normal recommendations response', () {
      final data = FriendRecommendationsData.fromJson({
        'count': 0,
        'recommendations': [
          {
            'id': 7,
            'username': 'adalovelace',
            'first_name': 'Ada',
            'last_name': 'Lovelace',
            'profile_image': '/media/ada.jpg',
            'connection_degree': 2,
            'reason_code': 'mutual_friends',
            'reason_label': 'Teniu amistats en comu',
            'shared_connections_count': 3,
          },
        ],
        'detail': 'ok',
      });

      expect(data.count, 0);
      expect(data.detail, 'ok');
      expect(data.recommendations, hasLength(1));

      final recommendation = data.recommendations.single;
      expect(recommendation.id, 7);
      expect(recommendation.username, 'adalovelace');
      expect(recommendation.displayName, 'Ada Lovelace');
      expect(recommendation.profileImage, '/media/ada.jpg');
      expect(recommendation.connectionDegree, 2);
      expect(recommendation.reasonCode, 'mutual_friends');
      expect(recommendation.reasonLabel, 'Teniu amistats en comu');
      expect(recommendation.sharedConnectionsCount, 3);
      expect(recommendation.toUserSummary().username, 'adalovelace');
    });

    test('parses an empty response', () {
      final data = FriendRecommendationsData.fromJson({
        'count': 0,
        'recommendations': [],
        'detail': 'No recommendations',
      });

      expect(data.count, 0);
      expect(data.recommendations, isEmpty);
      expect(data.detail, 'No recommendations');
    });

    test('defaults absent optional fields', () {
      final data = FriendRecommendationsData.fromJson({
        'recommendations': [
          {'id': 11, 'username': 'grace'},
        ],
      });

      expect(data.count, 1);
      expect(data.recommendations, hasLength(1));

      final recommendation = data.recommendations.single;
      expect(recommendation.id, 11);
      expect(recommendation.username, 'grace');
      expect(recommendation.firstName, isNull);
      expect(recommendation.lastName, isNull);
      expect(recommendation.profileImage, isNull);
      expect(recommendation.connectionDegree, 0);
      expect(recommendation.reasonCode, isNull);
      expect(recommendation.reasonLabel, isNull);
      expect(recommendation.sharedConnectionsCount, 0);
      expect(recommendation.displayName, 'grace');
    });

    test('treats malformed recommendations as an empty list', () {
      final data = FriendRecommendationsData.fromJson({
        'count': 4,
        'recommendations': {'id': 1},
      });

      expect(data.count, 4);
      expect(data.recommendations, isEmpty);
    });
  });
}
