import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';
import 'package:agendat/features/map/presentation/screens/map.dart';
import 'package:agendat/features/agenda/presentation/screens/calendar.dart';
import 'package:agendat/features/social/presentation/screens/social_screen.dart';

/// Índex de la pestanya arrel actualment seleccionada.
///
/// Es manté actualitzat per [RootNavigationScreen] perquè altres pantalles
/// puguin reaccionar quan l'usuari canvia de pestanya (per exemple, tancar
/// overlays transitoris com el llistat d'amics).
final ValueNotifier<int> rootTabIndexNotifier = ValueNotifier<int>(0);

/// Índex que ocupa la pestanya `Social` dins de [RootNavigationScreen]. Es
/// manté com a constant pública perquè les pantalles que depenen de canvis
/// de pestanya no hagin de duplicar la posició.
const int kSocialTabIndex = 3;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasSession = await restoreSession();
  if (hasSession) {
    // Repoblem les caches dependents de la sessió (per exemple el conjunt
    // local d'usuaris bloquejats) abans de mostrar la primera pantalla. La
    // crida és "best effort" i ja gestiona els errors internament: si falla,
    // l'app es continua obrint amb normalitat.
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      await ProfileQuery.instance.bootstrapForAuthenticatedUser(myId);
    }
  }
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
    CalendarScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    rootTabIndexNotifier.value = _selectedIndex;
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });
    // Notifica a la resta de l'app que hi ha hagut canvi de pestanya. Les
    // pantalles que en depenen (overlays oberts, etc.) poden reaccionar i
    // tancar-se de manera coordinada.
    rootTabIndexNotifier.value = index;
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
