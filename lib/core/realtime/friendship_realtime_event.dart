import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';

abstract class FriendshipRealtimeEvent {
  const FriendshipRealtimeEvent({required this.type, required this.requestId});

  final String type;
  final String? requestId;

  factory FriendshipRealtimeEvent.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    final requestId = json['request_id']?.toString();

    switch (type) {
      case 'friend_request.created':
        return FriendRequestCreatedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friend_request.accepted':
        return FriendRequestAcceptedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          chatId: _parseOptionalInt(json['chat_id']),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friend_request.rejected':
        return FriendRequestRejectedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friend_request.cancelled':
        return FriendRequestCancelledEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friendship.blocked':
        return FriendshipBlockedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friendship.unblocked':
        return FriendshipUnblockedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'friendship.unfriended':
        return FriendshipUnfriendedEvent(
          requestId: requestId,
          actorId: _requiredInt(json, 'actor_id'),
          friendshipId: _parseFriendshipId(json),
          friendshipStatus: _requiredFriendshipStatus(json),
          counterpart: _requiredCounterpart(json),
          requestSnapshot: _parseRequestSnapshot(json),
        );
      case 'error':
        return FriendshipRealtimeErrorEvent(
          requestId: requestId,
          code: (json['code'] ?? 'unknown').toString(),
          message: (json['message'] ?? '').toString(),
        );
      default:
        throw FormatException('Unsupported friendship realtime event: $type');
    }
  }

  static FriendshipRealtimeEvent? tryParse(Map<String, dynamic> json) {
    try {
      return FriendshipRealtimeEvent.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static int _requiredInt(Map<String, dynamic> json, String key) {
    final value = _parseOptionalInt(json[key]);
    if (value != null) return value;
    throw FormatException('Expected "$key" to be an integer.');
  }

  static int _parseFriendshipId(Map<String, dynamic> json) {
    final explicit = _parseOptionalInt(json['friendship_id']);
    if (explicit != null) return explicit;

    final friendship = json['friendship'];
    if (friendship is Map<String, dynamic>) {
      final nested = _parseOptionalInt(
        friendship['id'] ?? friendship['id_friendship'],
      );
      if (nested != null) return nested;
    }

    throw const FormatException('Missing friendship_id.');
  }

  static FriendshipStatus _requiredFriendshipStatus(Map<String, dynamic> json) {
    final status = friendshipStatusFromString(
      json['friendship_status']?.toString(),
    );
    if (status != null) return status;
    throw const FormatException('Missing or invalid friendship_status.');
  }

  static UserSummary _requiredCounterpart(Map<String, dynamic> json) {
    final counterpart = _parseUser(json['counterpart']);
    if (counterpart != null) return counterpart;

    final friendship = json['friendship'];
    if (friendship is Map<String, dynamic>) {
      final nested = _parseUser(friendship['counterpart']);
      if (nested != null) return nested;
    }

    throw const FormatException('Missing counterpart.');
  }

  static PendingFriendRequest? _parseRequestSnapshot(
    Map<String, dynamic> json,
  ) {
    final friendship = json['friendship'];
    if (friendship is! Map<String, dynamic>) return null;

    final id = _parseOptionalInt(
      friendship['id'] ?? friendship['id_friendship'] ?? json['friendship_id'],
    );
    final counterpart = _parseUser(
      friendship['counterpart'] ?? json['counterpart'],
    );
    if (id == null || counterpart == null) return null;

    return PendingFriendRequest(
      id: id,
      status: (friendship['status'] ?? 'pending').toString(),
      counterpart: counterpart,
      requestedBy: _parseUser(friendship['requested_by']),
      blockedBy: _parseUser(friendship['blocked_by']),
      createdAt: _parseOptionalDateTime(friendship['created_at']),
    );
  }

  static UserSummary? _parseUser(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return UserSummary.fromJson(raw);
    }
    return null;
  }

  static int? _parseOptionalInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '');
  }

  static DateTime? _parseOptionalDateTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}

abstract class FriendshipRealtimeMutationEvent extends FriendshipRealtimeEvent {
  const FriendshipRealtimeMutationEvent({
    required super.type,
    required super.requestId,
    required this.actorId,
    required this.friendshipId,
    required this.friendshipStatus,
    required this.counterpart,
    this.chatId,
    this.requestSnapshot,
  });

  final int actorId;
  final int friendshipId;
  final FriendshipStatus friendshipStatus;
  final UserSummary counterpart;
  final int? chatId;
  final PendingFriendRequest? requestSnapshot;
}

class FriendRequestCreatedEvent extends FriendshipRealtimeMutationEvent {
  const FriendRequestCreatedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friend_request.created');
}

class FriendRequestAcceptedEvent extends FriendshipRealtimeMutationEvent {
  const FriendRequestAcceptedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.chatId,
    super.requestSnapshot,
  }) : super(type: 'friend_request.accepted');
}

class FriendRequestRejectedEvent extends FriendshipRealtimeMutationEvent {
  const FriendRequestRejectedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friend_request.rejected');
}

class FriendRequestCancelledEvent extends FriendshipRealtimeMutationEvent {
  const FriendRequestCancelledEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friend_request.cancelled');
}

class FriendshipBlockedEvent extends FriendshipRealtimeMutationEvent {
  const FriendshipBlockedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friendship.blocked');
}

class FriendshipUnblockedEvent extends FriendshipRealtimeMutationEvent {
  const FriendshipUnblockedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friendship.unblocked');
}

class FriendshipUnfriendedEvent extends FriendshipRealtimeMutationEvent {
  const FriendshipUnfriendedEvent({
    required super.requestId,
    required super.actorId,
    required super.friendshipId,
    required super.friendshipStatus,
    required super.counterpart,
    super.requestSnapshot,
  }) : super(type: 'friendship.unfriended');
}

class FriendshipRealtimeErrorEvent extends FriendshipRealtimeEvent {
  const FriendshipRealtimeErrorEvent({
    required super.requestId,
    required this.code,
    required this.message,
  }) : super(type: 'error');

  final String code;
  final String message;
}
