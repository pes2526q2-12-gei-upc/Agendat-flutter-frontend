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
  final bool acceptedForModeration;

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
    this.acceptedForModeration = false,
  });

  ReviewDto copyWith({bool? acceptedForModeration}) {
    return ReviewDto(
      id: id,
      eventCode: eventCode,
      userId: userId,
      authorName: authorName,
      general: general,
      preu: preu,
      ambient: ambient,
      accessibilitat: accessibilitat,
      comment: comment,
      imageUrls: imageUrls,
      createdAt: createdAt,
      likesCount: likesCount,
      isLikedByMe: isLikedByMe,
      acceptedForModeration:
          acceptedForModeration ?? this.acceptedForModeration,
    );
  }

  factory ReviewDto.fromJson(Map<String, dynamic> json) {
    // Format real del backend:
    // reviewer_id / reviewer_username / created_at / likes_count / liked_by_me.
    return ReviewDto(
      id: json['id'] as int?,
      eventCode: '',
      userId: _asNullableString(json['reviewer_id']),
      authorName: _asNullableString(json['reviewer_username']),
      general: _asInt(json['rating']),
      preu: _asInt(json['price_rating']),
      ambient: _asInt(json['atmosphere_rating']),
      accessibilitat: _asInt(json['accessibility_rating']),
      comment: json['comment'] as String?,
      imageUrls: _parseImageUrls(json['images']),
      createdAt: json['created_at'] as String?,
      likesCount: _asInt(json['likes_count']),
      isLikedByMe: _asBool(json['liked_by_me']),
    );
  }

  static String? _asNullableString(dynamic raw) {
    if (raw == null) return null;
    return raw.toString();
  }

  static bool _asBool(dynamic raw) {
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      switch (raw.trim().toLowerCase()) {
        case 'true':
        case '1':
          return true;
      }
    }
    return false;
  }

  static int _asInt(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is List) return raw.length;
    if (raw is String) return int.tryParse(raw.trim()) ?? 0;
    return 0;
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return [raw.trim()];
    }
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

  /// Cos per crear una ressenya nova.
  Map<String, dynamic> toCreateJson() {
    return _editableFields();
  }

  /// Cos per actualitzar una ressenya existent.
  Map<String, dynamic> toUpdateJson() => _editableFields();

  /// Converteix el DTO al model de domini que fa servir la UI.
  Review toModel() {
    return Review(
      id: id,
      authorId: userId,
      author: authorName ?? userId ?? '',
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
