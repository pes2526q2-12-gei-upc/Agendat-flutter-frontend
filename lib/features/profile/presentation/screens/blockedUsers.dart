import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuthenticated()) return;
      _loadBlockedUsers();
    });
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
          'Cal iniciar sessio per veure el llistat d\'usuaris bloquejats.',
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return false;
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
            'No s\'ha pogut carregar el llistat de bloquejats. Comprova la connexio.';
      });
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
          _buildCenteredMessage(
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
          _buildCenteredMessage(
            icon: Icons.block_outlined,
            title: 'No has bloquejat cap usuari.',
            subtitle:
                'Quan bloquegis algu, apareixera aqui perque el puguis revisar.',
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
        return _BlockedUserTile(user: user, onOpenProfile: _openUserProfile);
      },
    );
  }

  Widget _buildCenteredMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({required this.user, required this.onOpenProfile});

  final UserSummary user;
  final ValueChanged<UserSummary> onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final displayName = user.displayName.trim().isNotEmpty
        ? user.displayName.trim()
        : (user.username.trim().isNotEmpty ? user.username.trim() : 'Usuari');
    final username = user.username.trim();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onOpenProfile(user),
            child: _Avatar(profileImage: user.profileImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (username.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => onOpenProfile(user),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profileImage});

  final String? profileImage;

  @override
  Widget build(BuildContext context) {
    const radius = 24.0;
    const size = radius * 2;
    final imageUrl = resolveProfileImageUrl(profileImage);

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 26, color: Colors.grey.shade500),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Icon(Icons.person, size: 26, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
