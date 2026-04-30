import 'dart:async';

import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart';
import 'package:agendat/features/agenda/presentation/screens/calendar.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';
import 'package:agendat/features/map/presentation/screens/map.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/presentation/screens/social_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Index of the currently selected root tab.
///
/// Kept in sync by [RootNavigationScreen] so other screens can react when the
/// user switches tabs, such as closing transient overlays.
final ValueNotifier<int> rootTabIndexNotifier = ValueNotifier<int>(0);

/// Index of the `Social` tab inside [RootNavigationScreen].
const int kSocialTabIndex = 3;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const forceLogin = bool.fromEnvironment('FORCE_LOGIN');
  if (forceLogin) {
    await clearLocalSession();
  }

  final hasSession = forceLogin ? false : await restoreSession();
  if (hasSession) {
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

  if (hasSession) {
    unawaited(
      PushNotificationsService.instance.requestPermissionAndRegisterDevice(),
    );
  }
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
