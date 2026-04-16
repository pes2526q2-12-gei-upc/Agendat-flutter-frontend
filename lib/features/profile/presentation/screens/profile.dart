import 'package:flutter/material.dart';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/logOut/presentation/screens/logOut.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/foundation.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.userId});

  /// Si és null, mostra el perfil de l'usuari actual.
  /// Si té un valor, mostra el perfil d'un altre usuari.
  final int? userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  static const _kPrimaryRed = Color(0xFFB71C1C);

  late TabController _tabController;
  bool _isLoading = true;
  UserProfile? _profile;
  UserStats? _stats;
  List<UserInterest> _interests = const [];
  List<UserSession> _sessions = const [];
  UserReviewsResponse? _reviewsResponse;
  String? _errorMessage;

  bool get _isOwnProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final userId = widget.userId ?? currentLoggedInUser?['id'] as int?;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No s\'ha pogut obtenir l\'identificador de l\'usuari.';
      });
      return;
    }

    final result = await fetchUserProfile(userId);

    if (!mounted) return;

    switch (result) {
      case ProfileSuccess(:final profile):
        final stats = await fetchUserStats(userId).catchError((_) {
          return const UserStats(eventCount: 0, reviewCount: 0, reputation: 0);
        });
        final interests = await fetchUserInterests(userId).catchError((_) {
          return const <UserInterest>[];
        });
        final reviewsResponse = await fetchUserReviews(userId).catchError((_) {
          return const UserReviewsResponse(count: 0, reviews: []);
        });
        final sessions = await fetchUserSessions(
          username: profile.username,
        ).catchError((_) => const <UserSession>[]);

        setState(() {
          _profile = profile;
          _stats = stats;
          _interests = interests;
          _reviewsResponse = reviewsResponse;
          _sessions = sessions;
          _isLoading = false;
        });
      case ProfileNotFound():
        setState(() {
          _isLoading = false;
          _errorMessage = 'Perfil no trobat.';
        });
      case ProfileUnavailable():
        setState(() {
          _isLoading = false;
          _errorMessage = 'Aquest perfil no està disponible.';
        });
      case ProfileFailure(:final statusCode, :final error):
        setState(() {
          _isLoading = false;
          _errorMessage = error != null
              ? 'Error de connexió. Comprova la teva connexió a internet.'
              : 'Error del servidor (codi $statusCode).';
        });
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_profile == null) return;

    final updatedProfile = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: _profile!),
      ),
    );

    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
      await setCurrentLoggedInUser({
        ...currentLoggedInUser ?? {},
        'username': updatedProfile.username,
        'email': updatedProfile.email,
        'first_name': updatedProfile.firstName,
        'last_name': updatedProfile.lastName,
        'description': updatedProfile.description,
        'profile_image': updatedProfile.profileImage,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _isOwnProfile ? 'El meu Perfil' : 'Perfil',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: !_isOwnProfile,
      iconTheme: const IconThemeData(color: Colors.black),
      actions: _isOwnProfile
          ? [
              IconButton(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black54,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('pendent')));
                },
              ),
            ]
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile!;
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(profile),
            const SizedBox(height: 16),
            _buildInterestsSection(_interests),
            const SizedBox(height: 16),
            _buildTabSection(
              attendedSessions: _sessions,
              reviewsResponse: _reviewsResponse,
            ),
            if (_isOwnProfile) ...[
              const SizedBox(height: 16),
              _buildLogoutButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(profile),
              const SizedBox(width: 16),
              Expanded(child: _buildProfileInfo(profile)),
              if (_isOwnProfile)
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                  onPressed: _navigateToEditProfile,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatsRow(_stats),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfile profile) {
    final imageUrl = resolveProfileImageUrl(profile.profileImage);
    const radius = 45.0;
    const size = radius * 2;

    if (imageUrl == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
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
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Icon(Icons.person, size: 50, color: Colors.grey.shade400),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileInfo(UserProfile profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.displayName,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        _buildRatingBadge(_stats?.reputation),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                profile.displayDescription,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingBadge(double? reputation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.amber.shade700),
          const SizedBox(width: 4),
          Text(
            reputation == null ? '—' : reputation.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(UserStats? stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('${stats?.eventCount ?? 0}', 'Esdeveniments'),
        _buildStatItem('${stats?.reviewCount ?? 0}', 'Valoracions'),
        _buildStatItem(
          stats == null ? '—' : stats.reputation.toStringAsFixed(1),
          'Reputació',
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _kPrimaryRed,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(List<UserInterest> interests) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isOwnProfile ? 'Els meus interessos' : 'Interessos',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isOwnProfile)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Editar interessos pendent'),
                      ),
                    );
                  },
                  child: const Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kPrimaryRed,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (interests.isEmpty)
            Text(
              'Cap interès afegit',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests
                  .map(
                    (i) => Chip(
                      label: Text(i.name),
                      backgroundColor: Colors.grey.shade100,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSection({
    required List<UserSession> attendedSessions,
    required UserReviewsResponse? reviewsResponse,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          const BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: _kPrimaryRed,
            unselectedLabelColor: Colors.grey.shade600,
            indicatorColor: _kPrimaryRed,
            indicatorWeight: 3,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            tabs: [
              const Tab(text: 'Assistits'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ressenyes'),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${reviewsResponse?.count ?? 0}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendedSessionsTab(attendedSessions),
                _buildReviewsTab(reviewsResponse),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendedSessionsTab(List<UserSession> sessions) {
    if (sessions.isEmpty) {
      return _buildEmptyTabContent(
        'No hi ha esdeveniments',
        Icons.event_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final s = sessions[index];
        final start = s.startTime;
        final startLabel =
            '${start.year.toString().padLeft(4, '0')}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')} '
            '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.event, color: Colors.grey.shade600),
          title: Text(
            s.eventCode.isEmpty ? 'Event' : s.eventCode,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(startLabel),
        );
      },
    );
  }

  Widget _buildReviewsTab(UserReviewsResponse? response) {
    final reviews = response?.reviews ?? const <UserReview>[];
    if (reviews.isEmpty) {
      return _buildEmptyTabContent(
        'No hi ha ressenyes',
        Icons.rate_review_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) {
        final r = reviews[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.rate_review, color: Colors.grey.shade600),
          title: Text(
            r.reviewerUsername.isEmpty ? 'Usuari' : r.reviewerUsername,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(r.comment.isEmpty ? '—' : r.comment),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '${r.rating}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTabContent(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LogOutScreen()));
        },
        icon: const Icon(Icons.logout_outlined),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryRed,
          side: const BorderSide(color: _kPrimaryRed),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        label: const Text(
          'Tancar sessió',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
