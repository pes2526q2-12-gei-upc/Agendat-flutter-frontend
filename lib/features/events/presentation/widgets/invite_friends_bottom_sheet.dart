import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/models/event.dart';
import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/core/models/session.dart';
import 'package:agendat/core/query/invitations_query.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/events/presentation/widgets/invite_friend_tile.dart';
import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/utils/user_list_utils.dart';
import 'package:agendat/l10n/app_localizations.dart';

/// Modal bottom sheet que mostra els amics de l'usuari autenticat per
/// convidar-los a una sessió concreta d'un esdeveniment. Permet cerca per
/// nom/username, multi-selecció, i mostra deshabilitats (amb badge) els
/// amics que ja tenen una invitació prèvia per aquesta sessió.
class InviteFriendsBottomSheet extends StatefulWidget {
  const InviteFriendsBottomSheet({
    super.key,
    required this.event,
    required this.session,
  });

  final Event event;
  final Session session;

  /// Mostra el bottom sheet i retorna el resum d'enviament (`null` si l'usuari
  /// el tanca sense enviar res).
  static Future<InviteFriendsResult?> show({
    required BuildContext context,
    required Event event,
    required Session session,
  }) {
    return showModalBottomSheet<InviteFriendsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InviteFriendsBottomSheet(event: event, session: session),
    );
  }

  @override
  State<InviteFriendsBottomSheet> createState() =>
      _InviteFriendsBottomSheetState();
}

/// Resum del que ha passat al confirmar l'enviament d'invitacions.
class InviteFriendsResult {
  const InviteFriendsResult({required this.successes, required this.errors});

  /// Invitacions creades correctament (en ordre d'enviament).
  final List<EventInvitation> successes;

  /// Errors per amic, indexat amb el resultat detallat.
  final List<InviteFriendError> errors;

  int get totalRequested => successes.length + errors.length;
}

class InviteFriendError {
  const InviteFriendError({required this.friend, required this.result});
  final UserSummary friend;
  final SendInvitationResult result;
}

class _InviteFriendsBottomSheetState extends State<InviteFriendsBottomSheet> {
  static const Color _accentRed = AppThemeTokens.brandPrimary;

  final ProfileQuery _profileQuery = ProfileQuery.instance;
  final InvitationsQuery _invitationsQuery = InvitationsQuery.instance;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _loading = true;
  String? _error;
  bool _sending = false;
  String _filter = '';

  List<UserSummary> _friends = const [];
  Map<int, EventInvitation> _existingByRecipient =
      const <int, EventInvitation>{};
  final Set<int> _selectedIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final myId = currentLoggedInUser?['id'];
    if (myId is! int) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).loginRequiredToManageInvitations;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final friendsFuture = _profileQuery.getFriends(myId, forceRefresh: true);
      final existingFuture = _invitationsQuery
          .getForSession(widget.session.id, forceRefresh: true)
          .catchError((Object error, StackTrace _) {
            if (kDebugMode) {
              debugPrint('[invite-sheet] failed to load existing: $error');
            }
            return <EventInvitation>[];
          });

      final friends = await friendsFuture;
      final existing = await existingFuture;

      if (!mounted) return;
      setState(() {
        _friends = sortUsersByDisplayName(
          _filterAuthorisedFriends(friends, myId),
        );
        _existingByRecipient = <int, EventInvitation>{
          for (final inv in existing)
            if (inv.recipient != null) inv.recipient!.id: inv,
        };
        _loading = false;
      });
    } catch (e, st) {
      if (kDebugMode) debugPrint('[invite-sheet] bootstrap: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).actionFailedFallback;
      });
    }
  }

  /// Treu de la llista d'amics els bloquejats/eliminats localment i a mi
  /// mateix (que mai pot ser destinatari).
  List<UserSummary> _filterAuthorisedFriends(
    List<UserSummary> friends,
    int myId,
  ) {
    final blockedIds = _profileQuery.locallyBlockedUserIds;
    final unfriendedIds = _profileQuery.locallyUnfriendedUserIds;
    return friends
        .where(
          (u) =>
              u.id != myId &&
              !blockedIds.contains(u.id) &&
              !unfriendedIds.contains(u.id),
        )
        .toList();
  }

  List<UserSummary> get _visibleFriends =>
      filterUsersByQuery(_friends, _filter);

  bool _isAlreadyInvited(UserSummary friend) =>
      _existingByRecipient.containsKey(friend.id);

  void _toggleSelection(UserSummary friend) {
    if (_isAlreadyInvited(friend)) return;
    setState(() {
      if (_selectedIds.contains(friend.id)) {
        _selectedIds.remove(friend.id);
      } else {
        _selectedIds.add(friend.id);
      }
    });
  }

  Future<void> _send() async {
    if (_sending || _selectedIds.isEmpty) return;
    // Resolem cada id a un UserSummary una sola vegada per mantenir l'ordre.
    final friendsById = <int, UserSummary>{for (final f in _friends) f.id: f};
    final toInvite = _selectedIds
        .map((id) => friendsById[id])
        .whereType<UserSummary>()
        .toList();

    setState(() => _sending = true);

    final successes = <EventInvitation>[];
    final errors = <InviteFriendError>[];

    for (final friend in toInvite) {
      final outcome = await _invitationsQuery.sendInvitation(
        sessionId: widget.session.id,
        recipientId: friend.id,
      );
      switch (outcome) {
        case SendInvitationOutcomeSuccess(:final invitation):
          successes.add(invitation);
        case SendInvitationOutcomeError(:final result):
          errors.add(InviteFriendError(friend: friend, result: result));
      }
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(InviteFriendsResult(successes: successes, errors: errors));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.grey.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                _buildHandle(),
                _buildHeader(),
                _buildSearchBar(),
                Expanded(child: _buildBody(scrollController)),
                _buildFooter(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 44,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade400,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    final locale = MaterialLocalizations.of(context);
    final start = widget.session.startTime.toLocal();
    final dateLabel = locale.formatFullDate(start);
    final timeLabel = locale.formatTimeOfDay(
      TimeOfDay.fromDateTime(start),
      alwaysUse24HourFormat: true,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).inviteToSessionTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.event.title}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${AppLocalizations.of(context).date}: $dateLabel · ${AppLocalizations.of(context).time}: $timeLabel',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (value) => setState(() => _filter = value.trim()),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchChatHint,
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: _filter.isEmpty
              ? null
              : IconButton(
                  tooltip: AppLocalizations.of(context).clearSearch,
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    _searchController.clear();
                    _searchFocus.unfocus();
                    setState(() => _filter = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: _accentRed, width: 1.5),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _bootstrap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentRed,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_friends.isEmpty) {
      return _buildEmpty(
        icon: Icons.group_outlined,
        title: AppLocalizations.of(context).noFriendsYet,
        subtitle: AppLocalizations.of(context).noFriendsYetSubtitle,
      );
    }

    final visible = _visibleFriends;
    if (visible.isEmpty) {
      return _buildEmpty(
        icon: Icons.search_off,
        title: AppLocalizations.of(context).noFriendsMatchSearch,
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: visible.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final friend = visible[index];
        final existing = _existingByRecipient[friend.id];
        final disabled = existing != null;
        final selected = _selectedIds.contains(friend.id);
        return InviteFriendTile(
          friend: friend,
          selected: selected,
          disabled: disabled,
          existingStatus: existing?.status,
          onTap: () => _toggleSelection(friend),
        );
      },
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
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
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final label = count == 0
        ? l10n.selectAtLeastOneFriend
        : count == 1
        ? l10n.sendOneInvitation
        : l10n.sendInvitationsCount(count);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: (count == 0 || _sending) ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
