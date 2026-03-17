/// Model d'usuari per a la visualització del perfil.
/// Coincideix amb la resposta de GET /api/users/{id}/.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.birthDate,
    this.profileImage,
    this.locationAllowed = false,
    this.notificationsAllowed = true,
    this.description,
  });

  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final DateTime? birthDate;
  final String? profileImage;
  final bool locationAllowed;
  final bool notificationsAllowed;
  final String? description;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      profileImage: json['profile_image'] as String?,
      locationAllowed: json['location_allowed'] as bool? ?? false,
      notificationsAllowed: json['notifications_allowed'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  // Retorna el nom complet o el username si no hi ha nom.
  String get displayName {
    final parts = [
      firstName,
      lastName,
    ].whereType<String>().where((p) => p.trim().isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(' ') : username;
  }

  // Retorna la descripció o un text per defecte.
  String get displayDescription {
    final desc = description?.trim();
    return (desc == null || desc.isEmpty) ? 'Sense descripció' : desc;
  }
}

class UserStats {
  const UserStats({
    required this.eventCount,
    required this.reviewCount,
    required this.reputation,
  });

  final int eventCount;
  final int reviewCount;
  final double reputation;

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      reputation: (json['reputation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserInterest {
  const UserInterest({required this.id, required this.name});

  final int id;
  final String name;

  factory UserInterest.fromJson(Map<String, dynamic> json) {
    return UserInterest(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}

class UserReview {
  const UserReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.reviewerId,
    required this.reviewerUsername,
  });

  final int id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int reviewerId;
  final String reviewerUsername;

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: (json['id'] as num).toInt(),
      rating: (json['rating'] as num).toInt(),
      comment: (json['comment'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reviewerId: (json['reviewer_id'] as num?)?.toInt() ?? 0,
      reviewerUsername: (json['reviewer_username'] as String?) ?? '',
    );
  }
}

class UserReviewsResponse {
  const UserReviewsResponse({required this.count, required this.reviews});

  final int count;
  final List<UserReview> reviews;

  factory UserReviewsResponse.fromJson(Map<String, dynamic> json) {
    final rawReviews = (json['reviews'] as List?) ?? const [];
    return UserReviewsResponse(
      count: (json['count'] as num?)?.toInt() ?? rawReviews.length,
      reviews: rawReviews
          .whereType<Map<String, dynamic>>()
          .map(UserReview.fromJson)
          .toList(),
    );
  }
}

class UserSession {
  const UserSession({
    required this.id,
    required this.eventCode,
    required this.username,
    required this.startTime,
    this.endTime,
  });

  final int id;
  final String eventCode;
  final String username;
  final DateTime startTime;
  final DateTime? endTime;

  factory UserSession.fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse((json['start_time'] as String?) ?? '');
    final end = DateTime.tryParse((json['end_time'] as String?) ?? '');
    return UserSession(
      id: (json['id'] as num).toInt(),
      eventCode: (json['event'] as String?) ?? '',
      username: (json['user'] as String?) ?? '',
      startTime: start ?? DateTime.fromMillisecondsSinceEpoch(0),
      endTime: end,
    );
  }
}
