import 'package:agendat/core/models/review.dart';

/// DTO que es parla amb el backend per a les ressenyes.
///
/// Els camps que el servidor pot no retornar (o que encara no existeixen
/// en crear una ressenya nova) són nullables.
class ReviewDto {
  final int? id;
  final String eventCode;
  final String? userId;
  final String? authorName;
  final String? authorAvatarUrl;
  final int general;
  final int preu;
  final int ambient;
  final int accessibilitat;
  final String? comment;
  final List<String> imageUrls;
  final String? createdAt;
  final int likesCount;
  final bool isLikedByMe;

  const ReviewDto({
    this.id,
    required this.eventCode,
    this.userId,
    this.authorName,
    this.authorAvatarUrl,
    required this.general,
    required this.preu,
    required this.ambient,
    required this.accessibilitat,
    this.comment,
    this.imageUrls = const [],
    this.createdAt,
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    // El backend pot retornar l'usuari com a objecte anidat (`user`) amb
    // `id`/`username`, com a id pla, o com a `authorName`/`userId`
    // separats. Ho cobrim tot.
    final rawUser = json['user'];
    String? userFromNested;
    String? nameFromNested;
    String? avatarFromNested;
    if (rawUser is Map<String, dynamic>) {
      userFromNested = _asNullableString(rawUser['id']);
      nameFromNested = _asNullableString(
        rawUser['username'] ?? rawUser['name'],
      );
      avatarFromNested = _asNullableString(
        rawUser['profile_image'] ??
            rawUser['profileImage'] ??
            rawUser['avatar'] ??
            rawUser['avatar_url'],
      );
    } else if (rawUser != null) {
      userFromNested = _asNullableString(rawUser);
    }

    return ReviewDto(
      id: json['id'] as int?,
      eventCode: (json['eventCode'] ?? json['event_code'] ?? '') as String,
      userId:
          _asNullableString(json['userId'] ?? json['user_id']) ??
          userFromNested,
      authorName:
          _asNullableString(
            json['authorName'] ?? json['author_name'] ?? json['author'],
          ) ??
          nameFromNested,
      authorAvatarUrl:
          _asNullableString(
            json['authorAvatarUrl'] ??
                json['author_avatar_url'] ??
                json['profile_image'] ??
                json['profileImage'] ??
                json['avatar'] ??
                json['avatar_url'],
          ) ??
          avatarFromNested,
      general: ((json['rating'] ?? json['general'] ?? 0) as num).toInt(),
      preu: ((json['price_rating'] ?? json['preu'] ?? 0) as num).toInt(),
      ambient: ((json['atmosphere_rating'] ?? json['ambient'] ?? 0) as num)
          .toInt(),
      accessibilitat:
          ((json['accessibility_rating'] ?? json['accessibilitat'] ?? 0) as num)
              .toInt(),
      comment: json['comment'] as String?,
      imageUrls: _parseImageUrls(json['imageUrls'] ?? json['image_urls']),
      createdAt: (json['createdAt'] ?? json['created_at']) as String?,
      likesCount: ((json['likesCount'] ?? json['likes_count'] ?? 0) as num)
          .toInt(),
      isLikedByMe:
          (json['isLikedByMe'] ?? json['is_liked_by_me'] ?? false) as bool,
    );
  }

  static String? _asNullableString(dynamic raw) {
    if (raw == null) return null;
    return raw.toString();
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  /// Camps editables comuns a create/update, amb els noms que espera el
  /// backend (`snake_case` + sufix `_rating`).
  Map<String, dynamic> _editableFields() {
    return <String, dynamic>{
      'rating': general,
      'price_rating': preu,
      'atmosphere_rating': ambient,
      'accessibility_rating': accessibilitat,
      'comment': comment ?? '',
    };
  }

  /// Cos per crear una ressenya nova (sense `id`). Només inclou `image_urls`
  /// si realment n'hi ha per no enviar-ho buit en la majoria de casos.
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      ..._editableFields(),
      if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
    };
  }

  /// Cos per actualitzar una ressenya existent.
  /// S'envia `image_urls` sempre per poder reemplaçar la galeria (fins i
  /// tot quan l'usuari les ha tret totes).
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{..._editableFields(), 'image_urls': imageUrls};
  }

  /// Converteix el DTO al model de domini que fa servir la UI.
  Review toModel() {
    return Review(
      id: id,
      author: authorName ?? userId ?? '',
      authorAvatarUrl: authorAvatarUrl,
      general: general,
      preu: preu,
      ambient: ambient,
      accessibilitat: accessibilitat,
      comment: comment,
      imageUrls: imageUrls,
      date: createdAt ?? '',
      likesCount: likesCount,
      isLikedByMe: isLikedByMe,
    );
  }
}
