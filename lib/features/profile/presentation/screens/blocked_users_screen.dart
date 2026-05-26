import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/api/api_error_utils.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/widgets/blocked_user_tile.dart';
import 'package:agendat/features/profile/presentation/widgets/blocked_users_centered_message.dart';
import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/core/utils/user_list_utils.dart';
import 'package:agendat/core/widgets/require_auth.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/core/models/user_summary.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context);

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

  bool get _isAuthenticated => isAuthenticated(requireUserId: true);

  bool _guardAuthenticated() => guardAuthenticated(
    context,
    message: AppLocalizations.of(context).loginRequired,
    requireUserId: true,
  );

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
        _blockedUsers = sortUsersByDisplayName(blocked);
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[blocked-users] load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = userMessageFromError(
          e,
          fallback: 'No s\'ha pogut carregar el llistat de bloquejats.',
        );
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
        _blockedUsers = sortUsersByDisplayName(blocked);
        _errorMessage = null;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[blocked-users] silent refresh failed: $e');
      if (mounted) setState(() {});
    }
  }

  Future<void> _openUserProfile(UserSummary user) async {
    await FeatureNavigation.openUserProfile(context, userId: user.id);
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
        title: Text(
          l10n.blockedUsersTitle,
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
            actionLabel: l10n.retry,
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
            title: l10n.noBlockedUsers,
            subtitle: l10n.blockedUsersSubtitle,
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
