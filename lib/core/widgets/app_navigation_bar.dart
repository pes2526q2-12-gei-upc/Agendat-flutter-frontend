import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.0),
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Inici',
          ),
          NavigationDestination(
            icon: Icon(Icons.map, color: Colors.white70),
            selectedIcon: Icon(Icons.map, color: Colors.white),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month, color: Colors.white70),
            selectedIcon: Icon(Icons.calendar_month, color: Colors.white),
            label: 'Calendari',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble, color: Colors.white70),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
