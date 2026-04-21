import 'package:agendat/core/api/locations_api.dart';
import 'package:agendat/core/query/query_client.dart';

class LocationsQuery {
  static final LocationsQuery instance = LocationsQuery._();
  LocationsQuery._();

  static const Duration staleTime = Duration(hours: 1);
  static const String _prefix = 'locations';

  final LocationsApi _api = LocationsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<String>> getProvincies({bool forceRefresh = false}) {
    return _client.query<List<String>>(
      key: '$_prefix:provincies',
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchProvincies();
        return _sortedNames(dtos.map((dto) => dto.name));
      },
    );
  }

  Future<List<String>> getComarques({
    String? provincia,
    bool forceRefresh = false,
  }) {
    return _client.query<List<String>>(
      key: '$_prefix:comarques:${provincia ?? ''}',
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchComarques(provincia: provincia);
        return _sortedNames(dtos.map((dto) => dto.name));
      },
    );
  }

  Future<List<String>> getMunicipis({
    String? provincia,
    String? comarca,
    bool forceRefresh = false,
  }) {
    return _client.query<List<String>>(
      key: '$_prefix:municipis:${provincia ?? ''}:${comarca ?? ''}',
      staleTime: staleTime,
      forceRefresh: forceRefresh,
      queryFn: () async {
        final dtos = await _api.fetchMunicipis(
          provincia: provincia,
          comarca: comarca,
        );
        return _sortedNames(dtos.map((dto) => dto.name));
      },
    );
  }

  void invalidateAll() => _client.invalidatePrefix(_prefix);
}

List<String> _sortedNames(Iterable<String> raw) {
  final list = raw.where((name) => name.isNotEmpty).toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return list;
}
