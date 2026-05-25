import 'package:agendat/core/models/user_summary.dart';

/// Ordenació alfabètica per [UserSummary.displayName], amb desempat per
/// [UserSummary.username] (case-insensitive).
List<UserSummary> sortUsersByDisplayName(List<UserSummary> users) {
  final sorted = [...users];
  sorted.sort((a, b) {
    final aKey = a.displayName.toLowerCase();
    final bKey = b.displayName.toLowerCase();
    final byName = aKey.compareTo(bKey);
    if (byName != 0) return byName;
    return a.username.toLowerCase().compareTo(b.username.toLowerCase());
  });
  return sorted;
}

/// Filtra usuaris per coincidència parcial a username o displayName.
List<UserSummary> filterUsersByQuery(List<UserSummary> users, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return users;
  final lowered = trimmed.toLowerCase();
  return users
      .where(
        (u) =>
            u.username.toLowerCase().contains(lowered) ||
            u.displayName.toLowerCase().contains(lowered),
      )
      .toList();
}
