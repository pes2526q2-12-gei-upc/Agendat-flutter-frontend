import 'dart:convert';
import 'package:agendat/core/services/baseURL_api.dart';
import 'package:http/http.dart' as http;

class CategoriesApiService {
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
  };

  Future<List<String>> fetchCategories() async {
    final uri = Uri.parse('${getBaseUrl()}/api/categories/');
    final response = await http
        .get(uri, headers: _jsonHeaders)
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Error fetching categories: HTTP ${response.statusCode}');
    }

    final List<dynamic> data = json.decode(response.body);
    return data
        .map((item) => (item['name'] as String).trim())
        .where((name) => name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
}
