/// Parses profile image URL from common API field names.
String? profileImageFromJson(Map<String, dynamic> json) {
  const keys = <String>[
    'profile_image',
    'profile_image_url',
    'profile_picture',
    'avatar',
    'photo',
    'image',
  ];
  for (final key in keys) {
    final v = json[key];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}
