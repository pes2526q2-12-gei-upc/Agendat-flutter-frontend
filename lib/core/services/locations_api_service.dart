import 'package:agendat/core/services/baseURL_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationsApiService {
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  Future<List<String>> fetchProvincies() async {
    final uri = Uri.parse('${getBaseUrl()}/api/provincies/');
    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Error fetching provincies: HTTP ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((item) => (item['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchComarques({String? provincia}) async {
    final uri = provincia != null
        ? Uri.parse('${getBaseUrl()}/api/comarques/').replace(
            queryParameters: {'provincia': provincia},
          )
        : Uri.parse('${getBaseUrl()}/api/comarques/');

    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Error fetching comarques: HTTP ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((item) => (item['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchMunicipis({
    String? comarca,
    String? provincia,
  }) async {
    final queryParams = <String, String>{};
    if (comarca != null) queryParams['comarca'] = comarca;
    if (provincia != null) queryParams['provincia'] = provincia;

    final uri = Uri.parse('${getBaseUrl()}/api/municipis/').replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Error fetching municipis: HTTP ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((item) => (item['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }
}
