import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/entities/product.dart';
import '../../domain/services/product_search_normalizer.dart';
import '../dtos/product_dto.dart';
import '../mappers/product_mapper.dart';
import 'product_remote_search_data_source.dart';

@LazySingleton(as: ProductRemoteSearchDataSource)
final class FirestoreProductRemoteSearchDataSource
    implements ProductRemoteSearchDataSource {
  FirestoreProductRemoteSearchDataSource(
    FirebaseFirestore firestore,
    this._mapper,
  ) : _collection = FirestoreCollectionDataSource<ProductDto>(
        firestore: firestore,
        collectionName: 'products',
        converter: FirestoreConverter<ProductDto>(
          fromJson: (data, id) => ProductDto.fromJson(data, id: id),
          toJson: (value) => value.toJson(),
        ),
      );

  final ProductMapper _mapper;
  final FirestoreCollectionDataSource<ProductDto> _collection;

  @override
  Future<List<Product>> searchProducts({
    required String organizationId,
    required String normalizedQuery,
    int limit = 20,
  }) async {
    if (normalizedQuery.trim().isEmpty) return const <Product>[];

    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) => query
          .where('organizationId', isEqualTo: organizationId)
          .where('deletedAt', isNull: true)
          .where('searchPrefixes', arrayContains: normalizedQuery),
    );

    return page.items
        .map(_mapper.toEntity)
        .where(
          (product) =>
              product.organizationId == organizationId &&
              product.deletedAt == null &&
              ProductSearchNormalizer.productMatches(product, normalizedQuery),
        )
        .toList(growable: false);
  }
}
