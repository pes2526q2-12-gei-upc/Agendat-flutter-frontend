import 'package:agendat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.socialUnreadConversationCount = 0,
    this.socialPendingFriendRequestsCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int socialUnreadConversationCount;
  final int socialPendingFriendRequestsCount;

  static const Color _badgeBlue = Color(0xFF1976D2);

  static Widget _socialIconWithBadge(
    Color color,
    int unreadConversations,
    int pendingFriendRequestsCount,
  ) {
    final icon = Icon(Icons.chat_bubble, color: color);
    final total = unreadConversations + pendingFriendRequestsCount;
    if (total <= 0) return icon;
    final label = total > 99 ? '99+' : '$total';
    return Badge(
      backgroundColor: _badgeBlue,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ClipRRect(
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: const Color.fromARGB(255, 152, 38, 30),
        indicatorColor: Colors.white24,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Colors.white);
          }
          return const TextStyle(color: Colors.white70);
        }),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.map, color: Colors.white70),
            selectedIcon: Icon(Icons.map, color: Colors.white),
            label: l10n.navMap,
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month, color: Colors.white70),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: l10n.navAgenda,
          ),
          NavigationDestination(
            icon: _socialIconWithBadge(
              Colors.white70,
              socialUnreadConversationCount,
              socialPendingFriendRequestsCount,
            ),
            selectedIcon: _socialIconWithBadge(
              Colors.white,
              socialUnreadConversationCount,
              socialPendingFriendRequestsCount,
            ),
            label: l10n.navSocial,
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
