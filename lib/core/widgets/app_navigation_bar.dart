import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.socialUnreadConversationCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int socialUnreadConversationCount;

  static Widget _socialIconWithBadge(Color color, int unreadConversations) {
    final icon = Icon(Icons.chat_bubble, color: color);
    if (unreadConversations <= 0) return icon;
    final label = unreadConversations > 99 ? '99+' : '$unreadConversations';
    return Badge(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFFB71C1C),
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Inici',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map, color: Colors.white70),
            selectedIcon: Icon(Icons.map, color: Colors.white),
            label: 'Mapa',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month, color: Colors.white70),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: 'Agenda',
          ),
          NavigationDestination(
            icon: _socialIconWithBadge(
              Colors.white70,
              socialUnreadConversationCount,
            ),
            selectedIcon: _socialIconWithBadge(
              Colors.white,
              socialUnreadConversationCount,
            ),
            label: 'Social',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
