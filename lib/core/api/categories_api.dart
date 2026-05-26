import 'dart:convert';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/category_dto.dart';

class CategoriesApi {
  static const String _path = '/api/categories/';

  Future<List<CategoryDto>> fetchCategories() async {
    final response = await ApiClient.get(_path);
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(CategoryDto.fromJson)
        .toList();
  }
}
