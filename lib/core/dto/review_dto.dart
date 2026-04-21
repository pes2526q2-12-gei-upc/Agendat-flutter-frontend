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
    return ReviewDto(
      id: json['id'] as int?,
      eventCode: (json['eventCode'] ?? json['event_code'] ?? '') as String,
      userId: (json['userId'] ?? json['user_id']) as String?,
      authorName:
          (json['authorName'] ?? json['author_name'] ?? json['author'])
              as String?,
      general: (json['general'] as num).toInt(),
      preu: (json['preu'] as num).toInt(),
      ambient: (json['ambient'] as num).toInt(),
      accessibilitat: (json['accessibilitat'] as num).toInt(),
      comment: json['comment'] as String?,
      imageUrls: _parseImageUrls(json['imageUrls'] ?? json['image_urls']),
      createdAt: (json['createdAt'] ?? json['created_at']) as String?,
      likesCount: ((json['likesCount'] ?? json['likes_count'] ?? 0) as num)
          .toInt(),
      isLikedByMe:
          (json['isLikedByMe'] ?? json['is_liked_by_me'] ?? false) as bool,
    );
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  /// Cos per crear una ressenya nova (sense `id`).
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'general': general,
      'preu': preu,
      'ambient': ambient,
      'accessibilitat': accessibilitat,
      if (comment != null) 'comment': comment,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
    };
  }

  /// Cos per actualitzar una ressenya existent (només camps editables).
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'general': general,
      'preu': preu,
      'ambient': ambient,
      'accessibilitat': accessibilitat,
      'comment': comment,
      'imageUrls': imageUrls,
    };
  }

  /// Serialització completa (útil per testos o cache).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'eventCode': eventCode,
      'userId': userId,
      'authorName': authorName,
      'general': general,
      'preu': preu,
      'ambient': ambient,
      'accessibilitat': accessibilitat,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': createdAt,
      'likesCount': likesCount,
      'isLikedByMe': isLikedByMe,
    };
  }

  /// Converteix el DTO al model de domini que fa servir la UI.
  Review toModel() {
    return Review(
      id: id,
      author: authorName ?? userId ?? '',
      general: general,
      preu: preu,
      ambient: ambient,
      accessibilitat: accessibilitat,
      comment: comment,
      imageUrls: imageUrls,
      date: createdAt ?? '',
    );
  }
}
