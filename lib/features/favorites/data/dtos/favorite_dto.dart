import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

/// Firestore document shape for
/// `organizations/{organizationId}/favorites/{userId}_{productId}`
/// (TASK-079). [id] mirrors [TeamDto]'s convention: it is the document's own
/// id (never one of [toJson]'s keys), always supplied out-of-band.
///
/// [organizationId]/[userId] are stored as fields (redundant with the
/// document's path/id) so Firestore Security Rules can validate ownership
/// without reading the path — `favorites/{productId}` rules gate every
/// read/write on `resource.data.userId == request.auth.uid`.
final class FavoriteDto {
  const FavoriteDto({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.productId,
    this.companyId,
    required this.createdAt,
  });

  factory FavoriteDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final userId = json['userId'];
    final productId = json['productId'];
    final companyId = json['companyId'];
    final createdAt = json['createdAt'];

    if (organizationId is! String ||
        userId is! String ||
        productId is! String ||
        (companyId != null && companyId is! String) ||
        createdAt is! Timestamp) {
      throw const ValidationException(
        'Invalid favorite payload.',
        code: 'invalid_favorite_payload',
      );
    }

    return FavoriteDto(
      id: id,
      organizationId: organizationId,
      userId: userId,
      productId: productId,
      companyId: companyId as String?,
      createdAt: createdAt.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String userId;
  final String productId;
  final String? companyId;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'userId': userId,
      'productId': productId,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
