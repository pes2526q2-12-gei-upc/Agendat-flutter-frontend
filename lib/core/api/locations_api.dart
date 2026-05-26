import 'dart:convert';
import 'package:agendat/core/api/api_client.dart';
import 'package:agendat/core/dto/location_dto.dart';

class LocationsApi {
  Future<List<ProvinciaDto>> fetchProvincies() async {
    final response = await ApiClient.get('/api/provincies/');
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProvinciaDto.fromJson)
        .toList();
  }

  Future<List<ComarcaDto>> fetchComarques({String? provincia}) async {
    final params = <String, String>{};
    if (provincia != null) params['provincia'] = provincia;

    final response = await ApiClient.get(
      '/api/comarques/',
      queryParams: params,
    );
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(ComarcaDto.fromJson)
        .toList();
  }

  Future<List<MunicipiDto>> fetchMunicipis({
    String? provincia,
    String? comarca,
  }) async {
    final params = <String, String>{};
    if (provincia != null) params['provincia'] = provincia;
    if (comarca != null) params['comarca'] = comarca;

    final response = await ApiClient.get(
      '/api/municipis/',
      queryParams: params,
    );
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .whereType<Map<String, dynamic>>()
        .map(MunicipiDto.fromJson)
        .toList();
  }
}
