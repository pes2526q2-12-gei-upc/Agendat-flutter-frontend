import 'dart:convert';

import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/event_invitation_dto.dart';

/// Resultat tipat per `InvitationsApi.sendInvitation`. Manté separats els
/// casos de negoci que tenen un missatge específic a la user story.
sealed class SendInvitationResult {}

class SendInvitationSuccess extends SendInvitationResult {
  SendInvitationSuccess(this.invitation);
  final EventInvitationDto invitation;
}

/// L'usuari no està autenticat o el token ja no és vàlid.
class SendInvitationUnauthorized extends SendInvitationResult {}

/// El destinatari no és vàlid (no és amic, és l'usuari mateix, no existeix...).
class SendInvitationInvalidRecipient extends SendInvitationResult {
  SendInvitationInvalidRecipient({this.message});
  final String? message;
}

/// L'esdeveniment no admet invitacions (cancel·lat, eliminat, finalitzat...).
class SendInvitationEventNotInvitable extends SendInvitationResult {
  SendInvitationEventNotInvitable({this.message});
  final String? message;
}

/// Ja existeix una invitació entre l'emissor i el destinatari per la mateixa
/// sessió/esdeveniment.
class SendInvitationDuplicate extends SendInvitationResult {
  SendInvitationDuplicate({this.message});
  final String? message;
}

class SendInvitationFailure extends SendInvitationResult {
  SendInvitationFailure({required this.statusCode, this.message, this.error});
  final int statusCode;
  final String? message;
  final Object? error;
}

/// Resultat tipat per `InvitationsApi.acceptInvitation`/`rejectInvitation`.
sealed class RespondInvitationResult {}

class RespondInvitationSuccess extends RespondInvitationResult {
  RespondInvitationSuccess(this.invitation);
  final EventInvitationDto invitation;
}

class RespondInvitationUnauthorized extends RespondInvitationResult {}

/// La invitació no existeix, ja s'ha respost prèviament, ha caducat o no està
/// adreçada a l'usuari autenticat.
class RespondInvitationInvalid extends RespondInvitationResult {
  RespondInvitationInvalid({this.message});
  final String? message;
}

class RespondInvitationFailure extends RespondInvitationResult {
  RespondInvitationFailure({
    required this.statusCode,
    this.message,
    this.error,
  });
  final int statusCode;
  final String? message;
  final Object? error;
}

/// API HTTP per al cicle de vida d'invitacions a sessions d'esdeveniments.
class InvitationsApi {
  static const String _invitationsBase = '/api/invitations';
  static const String _sessionsBase = '/api/sessions';

  /// POST /api/sessions/{sessionId}/invitations/
  Future<SendInvitationResult> sendInvitation({
    required int sessionId,
    required int recipientId,
  }) async {
    try {
      final response = await ApiClient.postJson(
        '$_sessionsBase/$sessionId/invitations/',
        body: <String, dynamic>{'recipient_id': recipientId},
        expectedStatusCode: 201,
      );
      final decoded = ApiClient.decodeBody(response);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected API response format');
      }
      return SendInvitationSuccess(EventInvitationDto.fromJson(decoded));
    } on ApiException catch (e) {
      return _mapSendApiException(e);
    } catch (e) {
      return SendInvitationFailure(statusCode: -1, error: e);
    }
  }

  /// POST /api/invitations/{invitationId}/accept/
  Future<RespondInvitationResult> acceptInvitation(int invitationId) =>
      _respondInvitation('$_invitationsBase/$invitationId/accept/');

  /// POST /api/invitations/{invitationId}/reject/
  Future<RespondInvitationResult> rejectInvitation(int invitationId) =>
      _respondInvitation('$_invitationsBase/$invitationId/reject/');

  Future<RespondInvitationResult> _respondInvitation(String path) async {
    try {
      final response = await ApiClient.postJson(
        path,
        body: const <String, dynamic>{},
        acceptedStatusCodes: const {200, 201},
      );
      final decoded = ApiClient.decodeBody(response);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected API response format');
      }
      return RespondInvitationSuccess(EventInvitationDto.fromJson(decoded));
    } on ApiException catch (e) {
      return _mapRespondApiException(e);
    } catch (e) {
      return RespondInvitationFailure(statusCode: -1, error: e);
    }
  }

  /// GET /api/invitations/received/?status=...
  Future<List<EventInvitationDto>> fetchReceived({String? status}) {
    return _fetchInvitationList('$_invitationsBase/received/', status: status);
  }

  /// GET /api/invitations/sent/?status=...
  Future<List<EventInvitationDto>> fetchSent({String? status}) {
    return _fetchInvitationList('$_invitationsBase/sent/', status: status);
  }

  /// GET /api/sessions/{sessionId}/invitations/
  Future<List<EventInvitationDto>> fetchForSession(int sessionId) {
    return _fetchInvitationList('$_sessionsBase/$sessionId/invitations/');
  }

  Future<List<EventInvitationDto>> _fetchInvitationList(
    String path, {
    String? status,
  }) async {
    final response = await ApiClient.get(
      path,
      queryParams: status == null || status.isEmpty
          ? null
          : <String, String>{'status': status},
    );
    final decoded = ApiClient.decodeBody(response);

    final List<dynamic> rawList;
    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final raw =
          decoded['invitations'] ?? decoded['results'] ?? decoded['data'];
      rawList = raw is List ? raw : const <dynamic>[];
    } else {
      rawList = const <dynamic>[];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(EventInvitationDto.fromJson)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Error mapping
  // ---------------------------------------------------------------------------

  SendInvitationResult _mapSendApiException(ApiException e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return SendInvitationUnauthorized();
    }
    if (e.statusCode == 409) {
      return SendInvitationDuplicate(message: _extractErrorMessage(e.body));
    }
    if (e.statusCode == 404) {
      return SendInvitationInvalidRecipient(
        message: _extractErrorMessage(e.body),
      );
    }
    if (e.statusCode == 400 || e.statusCode == 422) {
      final message = _extractErrorMessage(e.body) ?? '';
      final lowered = message.toLowerCase();
      final isEventIssue = _matchesAny(lowered, const [
        'event',
        'esdeveniment',
        'sessi',
        'cancel',
        'finalitz',
        'closed',
        'inactive',
        'inactiv',
      ]);
      final isDuplicate = _matchesAny(lowered, const [
        'duplicat',
        'duplicate',
        'already',
        'ja has',
        'ja existeix',
      ]);
      if (isDuplicate) {
        return SendInvitationDuplicate(message: message);
      }
      if (isEventIssue) {
        return SendInvitationEventNotInvitable(message: message);
      }
      return SendInvitationInvalidRecipient(message: message);
    }
    return SendInvitationFailure(
      statusCode: e.statusCode,
      message: _extractErrorMessage(e.body),
      error: e,
    );
  }

  RespondInvitationResult _mapRespondApiException(ApiException e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return RespondInvitationUnauthorized();
    }
    if (e.statusCode == 404 ||
        e.statusCode == 409 ||
        e.statusCode == 410 ||
        e.statusCode == 400 ||
        e.statusCode == 422) {
      return RespondInvitationInvalid(message: _extractErrorMessage(e.body));
    }
    return RespondInvitationFailure(
      statusCode: e.statusCode,
      message: _extractErrorMessage(e.body),
      error: e,
    );
  }

  bool _matchesAny(String text, List<String> needles) {
    for (final needle in needles) {
      if (text.contains(needle)) return true;
    }
    return false;
  }

  String? _extractErrorMessage(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        for (final key in const ['detail', 'message', 'error']) {
          final value = decoded[key];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        for (final entry in decoded.entries) {
          final value = entry.value;
          if (value is String && value.trim().isNotEmpty) return value.trim();
          if (value is List && value.isNotEmpty) {
            final first = value.first;
            if (first is String && first.trim().isNotEmpty) {
              return first.trim();
            }
          }
        }
      }
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is String && first.trim().isNotEmpty) return first.trim();
      }
    } catch (_) {
      // Not valid JSON; ignore and fall back to null.
    }
    return null;
  }
}
