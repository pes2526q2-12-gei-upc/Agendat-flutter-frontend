import 'package:agendat/core/api/invitations_api.dart';
import 'package:agendat/core/mappers/event_invitation_mapper.dart';
import 'package:agendat/core/models/event_invitation.dart';
import 'package:agendat/core/query/chats_query.dart';
import 'package:agendat/core/query/query_client.dart';
import 'package:agendat/core/query/sessions_query.dart';

export 'package:agendat/core/api/invitations_api.dart'
    show
        SendInvitationResult,
        SendInvitationSuccess,
        SendInvitationUnauthorized,
        SendInvitationInvalidRecipient,
        SendInvitationEventNotInvitable,
        SendInvitationDuplicate,
        SendInvitationFailure,
        RespondInvitationResult,
        RespondInvitationSuccess,
        RespondInvitationUnauthorized,
        RespondInvitationInvalid,
        RespondInvitationFailure;

/// Wrapper tipat sobre [SendInvitationResult] que retorna el model de domini
/// quan la crida té èxit. Manté l'enum-style de la resta de capes Query.
sealed class SendInvitationOutcome {}

class SendInvitationOutcomeSuccess extends SendInvitationOutcome {
  SendInvitationOutcomeSuccess(this.invitation);
  final EventInvitation invitation;
}

class SendInvitationOutcomeError extends SendInvitationOutcome {
  SendInvitationOutcomeError(this.result);
  final SendInvitationResult result;
}

sealed class RespondInvitationOutcome {}

class RespondInvitationOutcomeSuccess extends RespondInvitationOutcome {
  RespondInvitationOutcomeSuccess(this.invitation);
  final EventInvitation invitation;
}

class RespondInvitationOutcomeError extends RespondInvitationOutcome {
  RespondInvitationOutcomeError(this.result);
  final RespondInvitationResult result;
}

/// Capa Query (TanStack-style) sobre [InvitationsApi]: deduplicació, cache
/// amb `staleTime` curt (perquè els estats poden canviar amb freqüència) i
/// invalidació coordinada amb la resta de queries (xats, sessions).
class InvitationsQuery {
  static final InvitationsQuery instance = InvitationsQuery._();
  InvitationsQuery._();

  static const Duration _staleTime = Duration(seconds: 30);
  static const String _prefix = 'invitations';

  final InvitationsApi _api = InvitationsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<EventInvitation>> getReceived({
    String? status,
    bool forceRefresh = false,
  }) {
    return _client.query<List<EventInvitation>>(
      key: _receivedKey(status),
      staleTime: _staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchReceived(status: status);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<List<EventInvitation>> getSent({
    String? status,
    bool forceRefresh = false,
  }) {
    return _client.query<List<EventInvitation>>(
      key: _sentKey(status),
      staleTime: _staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchSent(status: status);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  /// Llista d'invitacions ja existents per una sessió de l'usuari emissor.
  /// S'utilitza al picker d'amics per mostrar el badge "Pendent / Acceptada /
  /// Denegada" als amics que ja tenen una invitació.
  Future<List<EventInvitation>> getForSession(
    int sessionId, {
    bool forceRefresh = false,
  }) {
    return _client.query<List<EventInvitation>>(
      key: _sessionKey(sessionId),
      staleTime: _staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchForSession(sessionId);
        return dtos.map((dto) => dto.toDomain()).toList();
      },
    );
  }

  Future<SendInvitationOutcome> sendInvitation({
    required int sessionId,
    required int recipientId,
  }) async {
    final result = await _api.sendInvitation(
      sessionId: sessionId,
      recipientId: recipientId,
    );
    if (result is SendInvitationSuccess) {
      final invitation = result.invitation.toDomain();

      // Quan s'envia una invitació nova, el xat associat tindrà un missatge
      // nou de tipus event_invitation. Invalidem les caches de xat i de
      // sessió per garantir que apareix tant al picker com a la conversa.
      _client.invalidate(_sessionKey(sessionId));
      _invalidateSentLists();
      final chatId = invitation.chatId;
      if (chatId != null) {
        ChatsQuery.instance.invalidateChat(chatId);
      }

      return SendInvitationOutcomeSuccess(invitation);
    }
    return SendInvitationOutcomeError(result);
  }

  Future<RespondInvitationOutcome> acceptInvitation(
    EventInvitation invitation,
  ) async {
    return _respondInvitation(
      invitation: invitation,
      apiCall: () => _api.acceptInvitation(invitation.id),
    );
  }

  Future<RespondInvitationOutcome> rejectInvitation(
    EventInvitation invitation,
  ) async {
    return _respondInvitation(
      invitation: invitation,
      apiCall: () => _api.rejectInvitation(invitation.id),
    );
  }

  Future<RespondInvitationOutcome> _respondInvitation({
    required EventInvitation invitation,
    required Future<RespondInvitationResult> Function() apiCall,
  }) async {
    final result = await apiCall();
    if (result is RespondInvitationSuccess) {
      final updated = result.invitation.toDomain();

      // Actualització optimista local al missatge de xat (la confirmació
      // arribarà igualment via WebSocket com a `message.created` re-emès amb
      // el mateix message_id).
      final chatId = updated.chatId ?? invitation.chatId;
      final messageId = updated.messageId ?? invitation.messageId;
      if (chatId != null && messageId != null) {
        ChatsQuery.instance.upsertInvitationStatusInMessage(
          chatId: chatId,
          messageId: messageId,
          invitation: updated,
        );
      }

      _invalidateReceivedLists();
      _invalidateSentLists();
      _client.invalidate(_sessionKey(updated.sessionId));

      // L'acceptació crea/afegeix l'usuari a la sessió: invalidem la llista
      // de sessions de l'usuari per refrescar l'agenda.
      if (updated.isAccepted) {
        SessionsQuery.instance.invalidateAll();
      }

      return RespondInvitationOutcomeSuccess(updated);
    }
    return RespondInvitationOutcomeError(result);
  }

  void invalidateAll() => _client.invalidatePrefix(_prefix);

  void invalidateSession(int sessionId) =>
      _client.invalidate(_sessionKey(sessionId));

  // ---------------------------------------------------------------------------
  // Cache key helpers
  // ---------------------------------------------------------------------------

  String _receivedKey(String? status) {
    final key = (status == null || status.isEmpty) ? 'all' : status;
    return '$_prefix:received:$key';
  }

  String _sentKey(String? status) {
    final key = (status == null || status.isEmpty) ? 'all' : status;
    return '$_prefix:sent:$key';
  }

  String _sessionKey(int sessionId) => '$_prefix:session:$sessionId';

  void _invalidateReceivedLists() =>
      _client.invalidatePrefix('$_prefix:received:');

  void _invalidateSentLists() => _client.invalidatePrefix('$_prefix:sent:');
}
