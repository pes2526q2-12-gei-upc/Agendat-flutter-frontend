class ProvinciaDto {
  final int id;
  final String name;

  const ProvinciaDto({required this.id, required this.name});

  factory ProvinciaDto.fromJson(Map<String, dynamic> json) {
    return ProvinciaDto(
      id: json['id'] as int,
      name: (json['name'] as String).trim(),
    );
  }
}

class ComarcaDto {
  final int id;
  final String name;
  final String provincia;

  const ComarcaDto({
    required this.id,
    required this.name,
    required this.provincia,
  });

  factory ComarcaDto.fromJson(Map<String, dynamic> json) {
    return ComarcaDto(
      id: json['id'] as int,
      name: (json['name'] as String).trim(),
      provincia: (json['provincia'] as String).trim(),
    );
  }
}

class MunicipiDto {
  final int id;
  final String name;
  final String comarca;
  final String provincia;

  const MunicipiDto({
    required this.id,
    required this.name,
    required this.comarca,
    required this.provincia,
  });

  factory MunicipiDto.fromJson(Map<String, dynamic> json) {
    return MunicipiDto(
      id: json['id'] as int,
      name: (json['name'] as String).trim(),
      comarca: (json['comarca'] as String).trim(),
      provincia: (json['provincia'] as String).trim(),
    );
  }
}
