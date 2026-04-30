class CategoryDto {
  final int? id;
  final String name;
  final String? emoji;

  const CategoryDto({this.id, required this.name, this.emoji});

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final emoji = ((json['emoji'] ?? '') as String).trim();
    return CategoryDto(
      id: json['id'] as int?,
      name: ((json['name'] ?? '') as String).trim(),
      emoji: emoji.isEmpty ? null : emoji,
    );
  }
}
