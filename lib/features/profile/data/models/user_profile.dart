/// Estat de la relació d'amistat del meu usuari amb un altre usuari.
///
/// El backend hauria de retornar aquest valor com a camp `friendship_status`
/// dins de la resposta de `GET /api/users/{id}/` per evitar crides extra i
/// inconsistències locals. Mentre el backend no l'enviï, es considera `null`.
enum FriendshipStatus {
  /// No són amics i no hi ha cap sol·licitud pendent.
  none,

  /// Jo he enviat una sol·licitud a l'altre usuari i està pendent.
  requestSent,

  /// L'altre usuari m'ha enviat una sol·licitud que jo encara no he respost.
  requestReceived,

  /// Ja som amics.
  friends,

  /// Tinc aquest usuari bloquejat.
  blocked,
}

FriendshipStatus? friendshipStatusFromString(String? raw) {
  if (raw == null) return null;
  switch (raw.toLowerCase().replaceAll('-', '_')) {
    case 'none':
    case '':
      return FriendshipStatus.none;
    case 'request_sent':
    case 'sent':
    case 'outgoing':
    case 'pending_sent':
      return FriendshipStatus.requestSent;
    case 'request_received':
    case 'received':
    case 'incoming':
    case 'pending_received':
      return FriendshipStatus.requestReceived;
    case 'friends':
    case 'friend':
    case 'accepted':
      return FriendshipStatus.friends;
    case 'blocked':
      return FriendshipStatus.blocked;
  }
  return null;
}

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
    this.eventRemindersAllowed = true,
    this.eventUpdatesAllowed = true,
    this.socialAlertsAllowed = true,
    this.description,
    this.friendshipStatus,
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
  final bool eventRemindersAllowed;
  final bool eventUpdatesAllowed;
  final bool socialAlertsAllowed;
  final String? description;

  /// Relació d'amistat de l'usuari autenticat envers aquest perfil. Només està
  /// present si el backend l'inclou a la resposta (camp `friendship_status`).
  final FriendshipStatus? friendshipStatus;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final notificationsAllowed = json['notifications_allowed'] as bool? ?? true;
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
      notificationsAllowed: notificationsAllowed,
      eventRemindersAllowed:
          json['event_reminders_allowed'] as bool? ?? notificationsAllowed,
      eventUpdatesAllowed:
          json['event_updates_allowed'] as bool? ?? notificationsAllowed,
      socialAlertsAllowed:
          json['social_alerts_allowed'] as bool? ?? notificationsAllowed,
      description: json['description'] as String?,
      friendshipStatus: friendshipStatusFromString(
        json['friendship_status'] as String?,
      ),
    );
  }

  UserProfile copyWithFriendshipStatus(FriendshipStatus? status) {
    return UserProfile(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      birthDate: birthDate,
      profileImage: profileImage,
      locationAllowed: locationAllowed,
      notificationsAllowed: notificationsAllowed,
      eventRemindersAllowed: eventRemindersAllowed,
      eventUpdatesAllowed: eventUpdatesAllowed,
      socialAlertsAllowed: socialAlertsAllowed,
      description: description,
      friendshipStatus: status,
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

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'description': description,
    'first_name': firstName,
    'last_name': lastName,
    'phone': phone,
    'birth_date': birthDate?.toIso8601String().split('T').first,
    'location_allowed': locationAllowed,
    'notifications_allowed': notificationsAllowed,
    'event_reminders_allowed': eventRemindersAllowed,
    'event_updates_allowed': eventUpdatesAllowed,
    'social_alerts_allowed': socialAlertsAllowed,
  };
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
