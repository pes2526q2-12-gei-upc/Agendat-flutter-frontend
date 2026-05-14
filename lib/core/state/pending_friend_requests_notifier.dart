import 'package:flutter/foundation.dart';

/// Nombre de sol·licituds d'amistat rebudes en estat pendent (badge pestanya Social).
final ValueNotifier<int> pendingFriendRequestsNotifier = ValueNotifier<int>(0);

void syncPendingFriendRequestsBadge(int receivedPendingCount) {
  pendingFriendRequestsNotifier.value = receivedPendingCount < 0
      ? 0
      : receivedPendingCount;
}
