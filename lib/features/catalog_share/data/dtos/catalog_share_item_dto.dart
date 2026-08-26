import '../../../../core/errors/errors.dart';

/// Wire shape of one shared product snapshot — identical whether it comes
/// from a Firestore document read (`CatalogShareDto`) or a callable Cloud
/// Function's plain-JSON response (`createCatalogShareLink`/
/// `getCatalogShareLink`): unlike the documents/responses that embed it,
/// an item itself carries no `Timestamp`/date field, so one parser serves
/// both shapes.
final class CatalogShareItemDto {
  const CatalogShareItemDto({
    required this.productId,
    required this.name,
    this.imageUrl,
  });

  factory CatalogShareItemDto.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'];
    final name = json['name'];
    final imageUrl = json['imageUrl'];

    if (productId is! String ||
        name is! String ||
        (imageUrl != null && imageUrl is! String)) {
      throw const ServerException(
        'Unexpected catalog share item shape.',
        code: 'invalid_catalog_share_item',
      );
    }

    return CatalogShareItemDto(
      productId: productId,
      name: name,
      imageUrl: imageUrl as String?,
    );
  }

  final String productId;
  final String name;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
