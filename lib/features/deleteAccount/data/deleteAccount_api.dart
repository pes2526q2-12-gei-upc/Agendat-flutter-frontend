import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/features/auth/data/users_api.dart';

sealed class DeleteAccountResult {}

class DeleteAccountSuccess extends DeleteAccountResult {}

class DeleteAccountUnauthorized extends DeleteAccountResult {}

class DeleteAccountFailure extends DeleteAccountResult {
  DeleteAccountFailure({required this.statusCode});
  final int statusCode;
}

Future<DeleteAccountResult> deleteAccountApi() async {
  final userId = currentLoggedInUser?['id'];

  if (currentLoggedInUser == null ||
      userId == null ||
      userId.toString().trim().isEmpty) {
    return DeleteAccountFailure(statusCode: -1);
  }

  try {
    // El backend retorna 204 en eliminar un usuari.
    await ApiClient.delete('/api/users/$userId/', expectedStatusCode: 204);
    await logout();
    return DeleteAccountSuccess();
  } on ApiException catch (e) {
    if (e.statusCode == 401 || e.statusCode == 403) {
      return DeleteAccountUnauthorized();
    }
    return DeleteAccountFailure(statusCode: e.statusCode);
  } catch (_) {
    return DeleteAccountFailure(statusCode: -1);
  }
}
