import 'package:agendat/core/api/locations_api.dart';
import 'package:agendat/core/query/query_client.dart';

class LocationsQuery {
  static const Duration staleTime = Duration(hours: 1);
  static const String _prefix = 'locations';

  final LocationsApi _api = LocationsApi();
  final QueryClient _client = QueryClient.instance;

  Future<List<String>> getProvincies() {
    return _client.query<List<String>>(
      key: '$_prefix:provincies',
      staleTime: staleTime,
      queryFn: () async {
        final dtos = await _api.fetchProvincies();
        return dtos
            .map((dto) => dto.name)
            .where((name) => name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      },
    );
  }

  Future<List<String>> getComarques({String? provincia}) {
    final key = provincia != null
        ? '$_prefix:comarques:$provincia'
        : '$_prefix:comarques';

    return _client.query<List<String>>(
      key: key,
      staleTime: staleTime,
      queryFn: () async {
        final dtos = await _api.fetchComarques(provincia: provincia);
        return dtos
            .map((dto) => dto.name)
            .where((name) => name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      },
    );
  }

  Future<List<String>> getMunicipis({String? provincia, String? comarca}) {
    final key = '$_prefix:municipis:${provincia ?? ''}:${comarca ?? ''}';

    return _client.query<List<String>>(
      key: key,
      staleTime: staleTime,
      queryFn: () async {
        final dtos = await _api.fetchMunicipis(
          provincia: provincia,
          comarca: comarca,
        );
        return dtos
            .map((dto) => dto.name)
            .where((name) => name.isNotEmpty)
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      },
    );
  }

  void invalidate() => _client.invalidatePrefix(_prefix);
}
