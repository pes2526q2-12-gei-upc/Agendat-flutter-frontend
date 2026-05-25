import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/core/utils/profile_image_json.dart';

/// Recomanació d'amistat retornada per
/// `GET /api/users/friend-recommendations/`.
class FriendRecommendation {
  const FriendRecommendation({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.profileImage,
    this.connectionDegree = 0,
    this.reasonCode,
    this.reasonLabel,
    this.sharedConnectionsCount = 0,
  });

  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profileImage;
  final int connectionDegree;
  final String? reasonCode;
  final String? reasonLabel;
  final int sharedConnectionsCount;

  factory FriendRecommendation.fromJson(Map<String, dynamic> json) {
    return FriendRecommendation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profileImage: profileImageFromJson(json),
      connectionDegree: (json['connection_degree'] as num?)?.toInt() ?? 0,
      reasonCode: json['reason_code'] as String?,
      reasonLabel: json['reason_label'] as String?,
      sharedConnectionsCount:
          (json['shared_connections_count'] as num?)?.toInt() ?? 0,
    );
  }

  UserSummary toUserSummary() {
    return UserSummary(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      profileImage: profileImage,
    );
  }

  String get displayName => toUserSummary().displayName;
}

/// Resposta de `GET /api/users/friend-recommendations/`.
class FriendRecommendationsData {
  const FriendRecommendationsData({
    required this.count,
    required this.recommendations,
    this.detail,
  });

  final int count;
  final List<FriendRecommendation> recommendations;
  final String? detail;

  static const FriendRecommendationsData empty = FriendRecommendationsData(
    count: 0,
    recommendations: [],
  );

  factory FriendRecommendationsData.fromJson(Map<String, dynamic> json) {
    final rawRecommendations = json['recommendations'];
    final recommendations = rawRecommendations is List
        ? rawRecommendations
              .whereType<Map<String, dynamic>>()
              .map(FriendRecommendation.fromJson)
              .toList()
        : const <FriendRecommendation>[];

    return FriendRecommendationsData(
      count: (json['count'] as num?)?.toInt() ?? recommendations.length,
      recommendations: recommendations,
      detail: json['detail'] as String?,
    );
  }
}
