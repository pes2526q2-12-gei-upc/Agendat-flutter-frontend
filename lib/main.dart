import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';
import 'package:agendat/features/map/presentation/screens/map.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSession = await restoreSession();
  runApp(
    MyApp(
      initialHome: hasSession
          ? const RootNavigationScreen()
          : const LoginScreen(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.initialHome});

  final Widget initialHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda\'t',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ca'), Locale('es'), Locale('en')],
      locale: const Locale('ca'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 105, 105),
        ),
      ),
      home: initialHome,
    );
  }
}

class RootNavigationScreen extends StatefulWidget {
  const RootNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootNavigationScreen> createState() => _RootNavigationScreenState();
}

class _RootNavigationScreenState extends State<RootNavigationScreen> {
  static const List<Widget> _screens = [
    VisualizeScreen(),
    MapScreen(),
    _PendingTabScreen(),
    _PendingTabScreen(),
    ProfileScreen(),
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;

    if (index == 2 || index == 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('pendent')));
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onDestinationSelected,
      ),
    );
  }
}

class _PendingTabScreen extends StatelessWidget {
  const _PendingTabScreen();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Aquesta pantalla encara no esta disponible.',
        textAlign: TextAlign.center,
      ),
    );
  }
}
