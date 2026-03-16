import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/features/auth/data/users_api.dart';
import 'package:http/http.dart' as http;

Future<bool> deleteAccountApi() async {
  final userId = currentLoggedInUser?['id'];

  if (currentLoggedInUser != null &&
      userId != null &&
      !userId.toString().trim().isEmpty) {
    final uri = Uri.parse('${getBaseUrl()}/api/users/${userId}/');
    final headers = <String, String>{'Accept': 'application/json'};

    try {
      final response = await http.delete(uri, headers: headers);
      final isSuccess =
          response.statusCode == 204 || response.statusCode == 200;
      if (isSuccess) {
        setCurrentLoggedInUser(null);
      }
      return isSuccess;
    } catch (_) {
      return false;
    }
  } else
    return false;
}
