import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class CreateGoogleEventRequest {
  CreateGoogleEventRequest({
    required this.summary,
    required this.description,
    required this.startTime,
    required this.endTime,
  });

  final String summary;
  final String description;
  final DateTime startTime;
  final DateTime endTime;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'summary': summary,
      'description': description,
      'start': {'dateTime': startTime.toUtc().toIso8601String()},
      'end': {'dateTime': endTime.toUtc().toIso8601String()},
    };
  }
}

class GoogleCalendarApi {
  static const String _baseUrl = 'https://www.googleapis.com/calendar/v3';
  static const Duration _timeout = Duration(seconds: 15);

  // Singleton GoogleSignIn instance to avoid multiple initializations
  static final GoogleSignIn _googleSignInInstance = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/calendar.events'],
    forceCodeForRefreshToken: true,
  );

  static GoogleSignIn get _googleSignIn => _googleSignInInstance;

  Future<String?> _getAccessToken() async {
    try {
      // First, try silent authentication (uses existing session from login)
      GoogleSignInAccount? account = await _googleSignIn.signInSilently();

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final token = auth.accessToken;
        if (token != null) {
          return token;
        }
      }

      // If silent auth failed and we're on web, skip interactive auth
      // (it's deprecated and unreliable). Calendar sync is best-effort only.
      if (kIsWeb) {
        print(
          'Google Calendar: Silent auth failed on web. Skipping calendar sync.',
        );
        return null;
      }

      // On mobile, try interactive sign-in as fallback
      account = await _googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.accessToken;
      }
    } on Exception catch (error) {
      print('Google Calendar: Error getting token: $error');
      // Don't rethrow - calendar sync is optional
    }
    return null;
  }

  Future<bool> createEvent(CreateGoogleEventRequest request) async {
    final accessToken = await _getAccessToken();

    if (accessToken == null) {
      print('Google Calendar: No access token available. Skipping sync.');
      return false;
    }

    final url = Uri.parse('$_baseUrl/calendars/primary/events');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Google Calendar: Event created successfully');
        return true;
      } else {
        print('Google Calendar: Failed with status ${response.statusCode}');
        if (kDebugMode) {
          print('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      print('Google Calendar: Connection error: $e');
      return false;
    }
  }
}
