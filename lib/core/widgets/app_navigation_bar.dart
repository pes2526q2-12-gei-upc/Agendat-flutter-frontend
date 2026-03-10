import 'package:agendat/features/deleteAccount/presentation/screens/deleteAccount.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';
import 'package:agendat/features/map/presentation/screens/map.dart';
import 'package:flutter/material.dart';

class AppNavigationBar extends StatelessWidget {
  const AppNavigationBar({super.key, required this.currentIndex});

  final int currentIndex;

  void onTapShowScreen(BuildContext context, int index) {
    if (index == currentIndex) return;

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        //substitueixo la pantalla (context) actual
        MaterialPageRoute(
          builder: (_) => const VisualizeScreen(),
        ), // per aquesta
      );
    } else if (index == 1) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MapScreen()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DeleteAccountScreen(),
        ), // temporal, haurem de posar la de perfil
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('pendent')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40.0),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => onTapShowScreen(context, index),
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
