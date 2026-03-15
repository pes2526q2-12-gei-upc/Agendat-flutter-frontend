import 'package:agendat/core/api/categories_api.dart';
import 'package:agendat/core/query/query_client.dart';

class CategoriesQuery {
  static const Duration staleTime = Duration(minutes: 30);
  static const String _key = 'categories';

  final CategoriesApi _api = CategoriesApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<String>> getCategories() {
    return _client.query<List<String>>(
      key: _key,
      staleTime: staleTime,
      queryFn: () async {
        final dtos = await _api.fetchCategories();
        return dtos
            .map((dto) => dto.name)
            .where((name) => name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      },
    );
  }

  void invalidate() => _client.invalidate(_key);
}
