import 'dart:async';

import 'package:agendat/core/navigation/app_navigator.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/realtime/chat_realtime_event.dart';
import 'package:agendat/core/realtime/chat_realtime_service.dart';
import 'package:agendat/core/realtime/friendship_realtime_event.dart';
import 'package:agendat/core/realtime/friendship_realtime_service.dart';
import 'package:agendat/core/state/pending_friend_requests_notifier.dart';
import 'package:agendat/core/state/unread_chat_conversations_notifier.dart';
import 'package:agendat/core/services/app_language.dart';
import 'package:agendat/core/services/push_notifications_service.dart';
import 'package:agendat/core/state/root_tab_state.dart';
import 'package:agendat/core/widgets/app_navigation_bar.dart';
import 'package:agendat/features/agenda/presentation/screens/calendar.dart';
import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/events/presentation/screens/visualize.dart';
import 'package:agendat/features/map/presentation/screens/map.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/presentation/screens/social_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agendat/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLanguage.loadFromStorage();

  const forceLogin = bool.fromEnvironment('FORCE_LOGIN');
  if (forceLogin) {
    await clearLocalSession();
  }

  final hasSession = forceLogin ? false : await restoreSession();
  if (hasSession) {
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      await ProfileQuery.instance.bootstrapForAuthenticatedUser(myId);
      await syncAuthenticatedUserLanguageFromBackend(myId);
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
    return ValueListenableBuilder<String>(
      valueListenable: AppLanguage.listenable,
      builder: (context, _, __) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: AppLanguage.toLocale(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 255, 105, 105),
            ),
            snackBarTheme: const SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          ),
          home: initialHome,
        );
      },
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
  StreamSubscription<ChatRealtimeEvent>? _chatRealtimeSubscription;
  StreamSubscription<FriendshipRealtimeEvent>? _friendshipRealtimeSubscription;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    rootTabIndexNotifier.value = _selectedIndex;
    _chatRealtimeSubscription = ChatRealtimeService.instance.events.listen(
      _onChatRealtimeEvent,
    );
    _friendshipRealtimeSubscription = FriendshipRealtimeService.instance.events
        .listen(_onFriendshipRealtimeEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _primeUnreadBadge());
  }

  @override
  void dispose() {
    _chatRealtimeSubscription?.cancel();
    _friendshipRealtimeSubscription?.cancel();
    super.dispose();
  }

  void _onChatRealtimeEvent(ChatRealtimeEvent event) {
    ChatsQuery.instance.applyRealtimeEvent(event);
  }

  void _onFriendshipRealtimeEvent(FriendshipRealtimeEvent event) {
    unawaited(ProfileQuery.instance.applyFriendshipRealtimeEvent(event));
  }

  Future<void> _primeUnreadBadge() async {
    if (currentAuthToken == null || currentAuthToken!.trim().isEmpty) {
      unreadChatConversationsNotifier.value = 0;
      pendingFriendRequestsNotifier.value = 0;
      return;
    }
    final myId = currentLoggedInUser?['id'];
    try {
      final chats = await ChatsQuery.instance.getChats();
      if (!mounted) return;
      syncUnreadChatConversationsBadge(chats);
    } catch (_) {
      /* es manté el valor anterior */
    }
    if (myId is! int) {
      pendingFriendRequestsNotifier.value = 0;
      return;
    }
    try {
      final data = await ProfileQuery.instance.getFriendRequests(myId);
      if (!mounted) return;
      final pending = data.received
          .where((r) => r.status.toLowerCase() == 'pending')
          .length;
      syncPendingFriendRequestsBadge(pending);
    } catch (_) {
      /* es manté el valor anterior */
    }
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
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: unreadChatConversationsNotifier,
        builder: (context, unreadConversations, _) {
          return ValueListenableBuilder<int>(
            valueListenable: pendingFriendRequestsNotifier,
            builder: (context, pendingFriendRequests, _) {
              return AppNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onDestinationSelected,
                socialUnreadConversationCount: unreadConversations,
                socialPendingFriendRequestsCount: pendingFriendRequests,
              );
            },
          );
        },
      ),
    );
  }
}
