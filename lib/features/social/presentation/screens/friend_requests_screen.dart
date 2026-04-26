import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:agendat/features/auth/presentation/screens/login_screen.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:agendat/features/profile/presentation/screens/profile.dart';
import 'package:agendat/features/social/data/models/user_summary.dart';
import 'package:agendat/features/social/data/social_api.dart';

/// Pantalla que llista les sol·licituds d'amistat pendents rebudes per
/// l'usuari autenticat i permet acceptar-les o rebutjar-les.
class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  static const _kPrimaryRed = Color(0xFFB71C1C);

  final ProfileQuery _profileQuery = ProfileQuery.instance;

  bool _isLoading = true;
  String? _errorMessage;
  List<PendingFriendRequest> _received = const [];

  /// Conjunt amb els ids de les sol·licituds que estan sent acceptades o
  /// rebutjades. Permet bloquejar els botons individualment sense afectar
  /// la resta de la llista.
  final Set<int> _busyRequestIds = <int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_guardAuthenticated()) return;
      _loadRequests();
    });
  }

  bool get _isAuthenticated =>
      currentAuthToken != null &&
      currentAuthToken!.trim().isNotEmpty &&
      currentLoggedInUser?['id'] is int;

  /// Si l'usuari no està autenticat, mostra el missatge d'error i el redirigeix
  /// a la pantalla de login. Retorna `true` si la sessió és vàlida.
  bool _guardAuthenticated() {
    if (_isAuthenticated || !mounted) return _isAuthenticated;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cal iniciar sessió per gestionar sol·licituds d\'amistat.',
        ),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    return false;
  }

  Future<void> _loadRequests({bool forceRefresh = false}) async {
    if (!_guardAuthenticated()) return;

    final myId = currentLoggedInUser!['id'] as int;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _profileQuery.getFriendRequests(
        myId,
        forceRefresh: forceRefresh,
      );

      if (!mounted) return;

      final pendingReceived = data.received
          .where((r) => r.status.toLowerCase() == 'pending')
          .toList();

      setState(() {
        _received = pendingReceived;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[friend-requests] load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'No s\'han pogut carregar les sol·licituds. Comprova la teva connexió.';
      });
    }
  }

  /// Identifica l'usuari remitent d'una sol·licitud rebuda. La resposta del
  /// backend posa el remitent a `counterpart` (i, redundantment, a
  /// `requested_by`); fem servir el primer not null.
  UserSummary? _senderOf(PendingFriendRequest request) {
    return request.counterpart ?? request.requestedBy;
  }

  Future<void> _acceptRequest(PendingFriendRequest request) {
    return _runAction(
      request: request,
      action: (userId) => acceptFriendRequest(userId),
      successMessage: 'Sol·licitud acceptada. Ara sou amics!',
      genericErrorMessage: 'No s\'ha pogut acceptar la sol·licitud.',
    );
  }

  Future<void> _rejectRequest(PendingFriendRequest request) {
    return _runAction(
      request: request,
      action: (userId) => rejectFriendRequest(userId),
      successMessage: 'Sol·licitud rebutjada.',
      genericErrorMessage: 'No s\'ha pogut rebutjar la sol·licitud.',
    );
  }

  Future<void> _runAction({
    required PendingFriendRequest request,
    required Future<FriendActionResult> Function(int userId) action,
    required String successMessage,
    required String genericErrorMessage,
  }) async {
    if (!_guardAuthenticated()) return;
    if (_busyRequestIds.contains(request.id)) return;

    final sender = _senderOf(request);
    if (sender == null) {
      _showSnack('Aquesta sol·licitud ja no és vàlida.');
      _removeRequest(request.id);
      return;
    }

    setState(() => _busyRequestIds.add(request.id));

    final result = await action(sender.id);

    if (!mounted) return;

    switch (result) {
      case FriendActionSuccess():
        setState(() {
          _busyRequestIds.remove(request.id);
          _received = _received.where((r) => r.id != request.id).toList();
        });
        _invalidateCaches(targetUserId: sender.id);
        _showSnack(successMessage);
      case FriendActionUnauthorized():
        setState(() => _busyRequestIds.remove(request.id));
        _guardAuthenticated();
      case FriendActionFailure(:final statusCode, :final error):
        setState(() => _busyRequestIds.remove(request.id));
        // 400/404/409/410 → la sol·licitud ja no és vàlida (no existeix,
        // ha caducat o ja s'ha respost). Treiem-la de la llista.
        if (_isInvalidRequestStatus(statusCode)) {
          _removeRequest(request.id);
          _showSnack('Aquesta sol·licitud ja no és vàlida.');
          // Refresquem la llista per assegurar coherència amb el backend.
          _invalidateCaches(targetUserId: sender.id);
          return;
        }
        final text = error != null && statusCode == -1
            ? 'Error de connexió. Comprova la teva connexió a internet.'
            : '$genericErrorMessage (codi $statusCode)';
        _showSnack(text);
    }
  }

  bool _isInvalidRequestStatus(int statusCode) {
    return statusCode == 400 ||
        statusCode == 404 ||
        statusCode == 409 ||
        statusCode == 410;
  }

  void _removeRequest(int requestId) {
    setState(() {
      _received = _received.where((r) => r.id != requestId).toList();
      _busyRequestIds.remove(requestId);
    });
  }

  void _invalidateCaches({required int targetUserId}) {
    final myId = currentLoggedInUser?['id'];
    if (myId is int) {
      _profileQuery.invalidateFriendshipLists(myId);
    }
    // El perfil de l'altre usuari pot mostrar l'estat d'amistat: l'invalidem
    // per assegurar-nos que la propera vegada que el visitem, mostri l'estat
    // actualitzat.
    _profileQuery.invalidateUser(targetUserId);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSenderProfile(UserSummary sender) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ProfileScreen(userId: sender.id)));
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
          'Sol·licituds d\'amistat',
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
        onRefresh: () => _loadRequests(forceRefresh: true),
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
            onAction: () => _loadRequests(forceRefresh: true),
          ),
        ],
      );
    }

    if (_received.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _buildCenteredMessage(
            icon: Icons.mark_email_read_outlined,
            title: 'No tens sol·licituds pendents.',
            subtitle: 'Quan algú et vulgui afegir, ho veuràs aquí.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _received.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final request = _received[index];
        return _FriendRequestTile(
          request: request,
          isBusy: _busyRequestIds.contains(request.id),
          onAccept: () => _acceptRequest(request),
          onReject: () => _rejectRequest(request),
          onTap: () {
            final sender = _senderOf(request);
            if (sender != null) _openSenderProfile(sender);
          },
        );
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
                  backgroundColor: _kPrimaryRed,
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

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.request,
    required this.isBusy,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  static const _kPrimaryRed = Color(0xFFB71C1C);

  final PendingFriendRequest request;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sender = request.counterpart ?? request.requestedBy;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: sender == null ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Avatar(profileImage: sender?.profileImage),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender?.displayName ?? 'Usuari desconegut',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (sender != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '@${sender.username}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (request.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(request.createdAt!),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : onAccept,
                        icon: isBusy
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Acceptar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryRed,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _kPrimaryRed.withValues(
                            alpha: 0.6,
                          ),
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: isBusy ? null : onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text(
                          'Rebutjar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimaryRed,
                          side: const BorderSide(color: _kPrimaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $hh:$mm';
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
        child: Icon(Icons.person, size: 26, color: Colors.grey.shade400),
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
