import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  static final GoogleCalendarService _instance =
      GoogleCalendarService._internal();

  factory GoogleCalendarService() {
    return _instance;
  }

  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'https://www.googleapis.com/auth/calendar.events'],
  );

  /// Get the access token from Google Sign-In
  /// Returns null if the user cancels or if there's an error
  Future<String?> getAccessToken() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        return auth.accessToken;
      }
    } catch (error) {
      print('Error during Google Sign-In: $error');
    }
    return null;
  }

  /// Check if the user is already signed in to Google
  Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  /// Get the currently signed-in account
  Future<GoogleSignInAccount?> getCurrentAccount() async {
    return await _googleSignIn.signInSilently();
  }

  /// Sign out from Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Create an event in Google Calendar
  /// Returns true if successful, false otherwise
  Future<bool> createCalendarEvent({
    required String accessToken,
    required String eventTitle,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
  }) async {
    final url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/primary/events',
    );

    final Map<String, dynamic> eventData = {
      'summary': eventTitle,
      if (description != null) 'description': description,
      'start': {'dateTime': startDateTime.toUtc().toIso8601String()},
      'end': {'dateTime': endDateTime.toUtc().toIso8601String()},
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(eventData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✓ Event created successfully in Google Calendar');
        return true;
      } else {
        print(
          '✗ Failed to create Google Calendar event. Status: ${response.statusCode}',
        );
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('✗ Error creating Google Calendar event: $e');
      return false;
    }
  }
}
