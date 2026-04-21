import 'package:agendat/core/api/categories_api.dart';
import 'package:agendat/core/query/query_client.dart';

class CategoriesQuery {
  static final CategoriesQuery instance = CategoriesQuery._();
  CategoriesQuery._();

  static const Duration staleTime = Duration(minutes: 30);
  static const String _key = 'categories';

  final CategoriesApi _api = CategoriesApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<String>> getCategories({bool forceRefresh = false}) {
    return _client.query<List<String>>(
      key: _key,
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchCategories();
        final list =
            dtos
                .map((dto) => dto.name)
                .where((name) => name.isNotEmpty)
                .toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return list;
      },
    );
  }

  void invalidate() => _client.invalidate(_key);
}
