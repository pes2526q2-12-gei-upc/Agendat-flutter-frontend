import 'package:agendat/core/dto/review_dto.dart';
import 'package:agendat/core/models/review.dart';

extension ReviewDtoMapper on ReviewDto {
  Review toDomain() {
    return Review(
      id: id,
      authorId: userId,
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
