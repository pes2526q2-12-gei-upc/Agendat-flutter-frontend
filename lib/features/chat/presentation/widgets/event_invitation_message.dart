import 'dart:async';

import 'package:flutter/material.dart';

import 'package:agendat/core/auth/auth_session_service.dart';
import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/invitations_query.dart';
import 'package:agendat/core/services/attendance_calendar_sync.dart';
import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/utils/chat_utils.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';
import 'package:agendat/core/widgets/avatars.dart';
import 'package:agendat/core/navigation/feature_navigation.dart';
import 'package:agendat/core/models/user_summary.dart';
import 'package:agendat/l10n/app_localizations.dart';

/// Bombolla especial per representar una invitació a una sessió d'esdeveniment
/// dins d'una conversa de xat. Mostra el títol de l'esdeveniment, la data/hora
/// de la sessió, un badge d'estat (Pendent / Acceptada / Denegada) i —només
/// quan jo soc el destinatari i la invitació encara està pendent— els botons
/// d'acció Acceptar/Denegar.
class EventInvitationMessage extends StatefulWidget {
  const EventInvitationMessage({
    super.key,
    required this.invitation,
    required this.messageId,
    required this.chatId,
    required this.sentAt,
    required this.isSentByMe,
    required this.partner,
    this.myAvatarUrl,
    this.myAvatarLabel,
    this.onInvitationUpdated,
  });

  final EventInvitation invitation;
  final int messageId;
  final int chatId;
  final DateTime sentAt;
  final bool isSentByMe;
  final UserSummary partner;
  final String? myAvatarUrl;
  final String? myAvatarLabel;
  final ValueChanged<EventInvitation>? onInvitationUpdated;

  @override
  State<EventInvitationMessage> createState() => _EventInvitationMessageState();
}

class _EventInvitationMessageState extends State<EventInvitationMessage> {
  static const Color _sentBubbleColor = AppThemeTokens.brandPrimary;
  static const Color _accentRed = AppThemeTokens.brandPrimary;

  final GoogleAttendanceCalendarClient _calendarSyncClient =
      GoogleAttendanceCalendarClient();

  bool _isResponding = false;

  /// Estat local després d'acceptar/rebutjar; prioritari fins que el pare
  /// sincronitzi `_messages` o arribi un `message.created` per WebSocket.
  EventInvitation? _resolvedInvitation;

  EventInvitation get _invitation => _resolvedInvitation ?? widget.invitation;

  @override
  void didUpdateWidget(EventInvitationMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.invitation.id != oldWidget.invitation.id) {
      _resolvedInvitation = null;
      return;
    }
    if (oldWidget.invitation.isPending && !widget.invitation.isPending) {
      _resolvedInvitation = null;
    }
  }

  /// Mostra els botons d'acció només quan sóc el destinatari i la invitació
  /// continua pendent.
  bool get _canRespond =>
      !widget.isSentByMe && _invitation.isPending && !_isResponding;

  bool get _addToGoogleCalendar =>
      (currentLoggedInUser?['calendar_sync_allowed'] as bool?) ?? true;

  Future<void> _accept() => _respond(accept: true);

  Future<void> _reject() => _respond(accept: false);

  Future<void> _respond({required bool accept}) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);

    final query = InvitationsQuery.instance;
    final outcome = accept
        ? await query.acceptInvitation(_invitation)
        : await query.rejectInvitation(_invitation);

    if (!mounted) return;

    switch (outcome) {
      case RespondInvitationOutcomeSuccess(:final invitation):
        ChatsQuery.instance.upsertInvitationStatusInMessage(
          chatId: widget.chatId,
          messageId: widget.messageId,
          invitation: invitation,
        );
        widget.onInvitationUpdated?.call(invitation);
        if (!mounted) return;
        setState(() {
          _resolvedInvitation = invitation;
          _isResponding = false;
        });
        final accepted = invitation.isAccepted;
        final calendarResult = accepted
            ? await syncAttendanceSessionToGoogleCalendar(
                calendarClient: _calendarSyncClient,
                calendarSyncAllowed: _addToGoogleCalendar,
                eventTitle: invitation.eventDenomination.isEmpty
                    ? AppLocalizations.of(context).eventLabel
                    : invitation.eventDenomination,
                startDateTime: invitation.sessionStartTime,
                endDateTime: invitation.sessionEndTime,
                description: AppLocalizations.of(
                  context,
                ).attendanceCalendarSyncDescription,
              )
            : AttendanceCalendarSyncResult.skipped;
        if (!mounted) return;
        final responseText =
            accepted && calendarResult == AttendanceCalendarSyncResult.failed
            ? AppLocalizations.of(context).attendanceCalendarSyncPartial
            : accepted
            ? AppLocalizations.of(context).invitationAcceptedRegistered
            : AppLocalizations.of(context).invitationRejected;
        AppSnackBar.show(
          context,
          responseText,
          isError:
              !accepted ||
              calendarResult == AttendanceCalendarSyncResult.failed,
        );
        return;
      case RespondInvitationOutcomeError(:final result):
        _showRespondErrorSnackbar(result);
    }

    if (mounted) {
      setState(() => _isResponding = false);
    }
  }

  void _showRespondErrorSnackbar(RespondInvitationResult result) {
    final String text;
    switch (result) {
      case RespondInvitationUnauthorized():
        text = AppLocalizations.of(context).loginRequiredToManageInvitations;
      case RespondInvitationInvalid():
        text = AppLocalizations.of(context).invitationNoLongerValid;
      case RespondInvitationFailure(:final message):
        text = message ?? AppLocalizations.of(context).actionFailedFallback;
      case RespondInvitationSuccess():
        return;
    }
    AppSnackBar.show(context, text);
  }

  void _openEventDetail() {
    unawaited(
      FeatureNavigation.openEventDetail(
        context,
        eventCode: _invitation.eventCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = widget.isSentByMe ? _sentBubbleColor : Colors.white;
    final onBubble = widget.isSentByMe ? Colors.white : Colors.black87;
    final timeLabel = ChatTimestampFormat.messageDetail(context, widget.sentAt);

    const avatarRadius = 18.0;
    final partnerAvatar = ProfileCircleAvatar(
      radius: avatarRadius,
      profileImage: widget.partner.profileImage,
      fallbackLabel: widget.partner.displayName,
    );
    final myAvatar = ProfileCircleAvatar(
      radius: avatarRadius,
      profileImage: widget.myAvatarUrl,
      fallbackLabel: widget.myAvatarLabel ?? '?',
    );

    final card = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(widget.isSentByMe ? 18 : 4),
          bottomRight: Radius.circular(widget.isSentByMe ? 4 : 18),
        ),
        border: widget.isSentByMe
            ? null
            : Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(theme, onBubble),
          _buildBody(theme, onBubble),
          if (_canRespond) _buildActionButtons() else _buildStatusFooter(theme),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              timeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: onBubble.withValues(
                  alpha: widget.isSentByMe ? 0.85 : 0.6,
                ),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              textAlign: widget.isSentByMe ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isSentByMe) ...[partnerAvatar, const SizedBox(width: 8)],
          Expanded(
            child: Align(
              alignment: widget.isSentByMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: card,
            ),
          ),
          if (widget.isSentByMe) ...[const SizedBox(width: 8), myAvatar],
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Color onBubble) {
    final iconBackground = widget.isSentByMe
        ? Colors.white.withValues(alpha: 0.16)
        : _accentRed.withValues(alpha: 0.10);
    final iconColor = widget.isSentByMe ? Colors.white : _accentRed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isSentByMe
                  ? AppLocalizations.of(context).invitationSentByYou
                  : AppLocalizations.of(context).invitationReceived,
              style: theme.textTheme.labelLarge?.copyWith(
                color: onBubble.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, Color onBubble) {
    final title = _invitation.eventDenomination.isEmpty
        ? AppLocalizations.of(context).eventLabel
        : _invitation.eventDenomination;
    final sessionLabel = _formatSessionWindow();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: _openEventDetail,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: onBubble,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: onBubble.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          if (sessionLabel != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: onBubble.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sessionLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: onBubble.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isResponding ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade400),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(AppLocalizations.of(context).deny),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isResponding ? null : _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isResponding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(AppLocalizations.of(context).accept),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(ThemeData theme) {
    final (label, icon, color) = _statusPresentation();
    final onBubble = widget.isSentByMe ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: widget.isSentByMe
              ? Colors.white.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: widget.isSentByMe ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: widget.isSentByMe ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_invitation.respondedAt != null) ...[
              const SizedBox(width: 8),
              Text(
                ChatTimestampFormat.messageDetail(
                  context,
                  _invitation.respondedAt!,
                ),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: onBubble.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, IconData, Color) _statusPresentation() {
    switch (_invitation.status) {
      case EventInvitationStatus.pending:
        return (
          AppLocalizations.of(context).invitationStatusPending,
          Icons.hourglass_top_rounded,
          Colors.orange,
        );
      case EventInvitationStatus.accepted:
        return (
          AppLocalizations.of(context).invitationStatusAccepted,
          Icons.check_circle_rounded,
          Colors.green,
        );
      case EventInvitationStatus.denied:
        return (
          AppLocalizations.of(context).invitationStatusDenied,
          Icons.cancel_rounded,
          Colors.redAccent,
        );
    }
  }

  String? _formatSessionWindow() {
    final start = _invitation.sessionStartTime;
    if (start == null) return null;
    final end = _invitation.sessionEndTime;
    final locale = MaterialLocalizations.of(context);
    final startLabel =
        '${locale.formatFullDate(start.toLocal())} · '
        '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(start.toLocal()), alwaysUse24HourFormat: true)}';
    if (end == null) return startLabel;
    final localEnd = end.toLocal();
    final localStart = start.toLocal();
    final sameDay =
        localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day;
    if (sameDay) {
      final endTime = locale.formatTimeOfDay(
        TimeOfDay.fromDateTime(localEnd),
        alwaysUse24HourFormat: true,
      );
      return '$startLabel – $endTime';
    }
    return '$startLabel → '
        '${locale.formatFullDate(localEnd)} · '
        '${locale.formatTimeOfDay(TimeOfDay.fromDateTime(localEnd), alwaysUse24HourFormat: true)}';
  }
}
