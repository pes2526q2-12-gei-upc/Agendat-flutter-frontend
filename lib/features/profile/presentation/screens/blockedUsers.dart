import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/widgets/blocked_user_tile.dart';
import 'package:agendat/features/profile/presentation/widgets/blocked_users_centered_message.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<UserSummary> _blockedUsers = const [];
  StreamSubscription<FriendshipChange>? _friendshipChangeSubscription;

  @override
  void initState() {
    super.initState();
    _friendshipChangeSubscription = _profileQuery.friendshipChanges.listen(
      _onFriendshipChange,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuthenticated()) return;
      _loadBlockedUsers();
    });
  }

  @override
  void dispose() {
    _friendshipChangeSubscription?.cancel();
    super.dispose();
  }

  bool get _isAuthenticated =>
      currentAuthToken != null &&
      currentAuthToken!.trim().isNotEmpty &&
      currentLoggedInUser?['id'] is int;

  bool _guardAuthenticated() {
    if (_isAuthenticated || !mounted) return _isAuthenticated;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cal iniciar sessió per veure el llistat d\'usuaris bloquejats.',
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return false;
  }

  void _onFriendshipChange(FriendshipChange change) {
    if (!_isAuthenticated || !mounted) return;
    unawaited(_refreshBlockedUsersFromCache());
  }

  Future<void> _loadBlockedUsers({bool forceRefresh = false}) async {
    if (!_guardAuthenticated()) return;
    final myId = currentLoggedInUser!['id'] as int;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final blocked = await _profileQuery.getBlockedUsers(
        myId,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;
      setState(() {
        _blockedUsers = _sortAlphabetically(blocked);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[blocked-users] load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No s\'ha pogut carregar el llistat de bloquejats. Comprova la connexió.';
      });
    }
  }

  Future<void> _refreshBlockedUsersFromCache() async {
    if (!_guardAuthenticated()) return;
    final myId = currentLoggedInUser!['id'] as int;

    try {
      final blocked = await _profileQuery.getBlockedUsers(myId);
      if (!mounted) return;
      setState(() {
        _blockedUsers = _sortAlphabetically(blocked);
        _errorMessage = null;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[blocked-users] silent refresh failed: $e');
      if (mounted) setState(() {});
    }
  }

  List<UserSummary> _sortAlphabetically(List<UserSummary> users) {
    final sorted = [...users];
    sorted.sort((a, b) {
      final byName = a.displayName.toLowerCase().compareTo(
        b.displayName.toLowerCase(),
      );
      if (byName != 0) return byName;
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return sorted;
  }

  Future<void> _openUserProfile(UserSummary user) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: user.id)));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Usuaris bloquejats',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadBlockedUsers(forceRefresh: true),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          BlockedUsersCenteredMessage(
            icon: Icons.error_outline,
            title: _errorMessage!,
            actionLabel: 'Reintentar',
            onAction: () => _loadBlockedUsers(forceRefresh: true),
          ),
        ],
      );
    }

    if (_blockedUsers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          BlockedUsersCenteredMessage(
            icon: Icons.block_outlined,
            title: 'No has bloquejat cap usuari.',
            subtitle:
                'Quan bloquegis algú, apareixerà aquí perquè el puguis revisar.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppScreenSpacing.horizontal,
        8,
        AppScreenSpacing.horizontal,
        AppScreenSpacing.bottom,
      ),
      itemCount: _blockedUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        return BlockedUserTile(user: user, onOpenProfile: _openUserProfile);
      },
    );
  }
}
