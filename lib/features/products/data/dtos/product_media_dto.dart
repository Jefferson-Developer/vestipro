import '../../../../core/errors/errors.dart';

/// Firestore/embedded shape of a single `ProductMedia` (TASK-068), the same
/// "list of small maps embedded in the parent document" pattern
/// `ProductCustomFieldValueDto` already uses — a product's media never
/// outgrows a handful of photos/one short video, so it does not need its
/// own subcollection.
final class ProductMediaDto {
  const ProductMediaDto({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    required this.order,
    this.principal = false,
    this.colorId,
  });

  factory ProductMediaDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final url = json['url'];
    final thumbnailUrl = json['thumbnailUrl'];
    final order = json['order'];
    final principal = json['principal'];
    final colorId = json['colorId'];

    if (id is! String ||
        type is! String ||
        url is! String ||
        (thumbnailUrl != null && thumbnailUrl is! String) ||
        order is! int ||
        (principal != null && principal is! bool) ||
        (colorId != null && colorId is! String)) {
      throw const ValidationException(
        'Invalid product media payload.',
        code: 'invalid_product_media_payload',
      );
    }

    return ProductMediaDto(
      id: id,
      type: type,
      url: url,
      thumbnailUrl: thumbnailUrl as String?,
      order: order,
      principal: (principal as bool?) ?? false,
      colorId: colorId as String?,
    );
  }

  final String id;
  final String type;
  final String url;
  final String? thumbnailUrl;
  final int order;
  final bool principal;
  final String? colorId;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'order': order,
      'principal': principal,
      'colorId': colorId,
    };
  }
}
