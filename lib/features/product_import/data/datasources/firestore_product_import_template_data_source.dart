import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/product_import_template_dto.dart';
import 'product_import_template_data_source.dart';

/// Firestore-backed [ProductImportTemplateDataSource] for
/// `organizations/{organizationId}/productImportTemplates` (TASK-168).
@LazySingleton(as: ProductImportTemplateDataSource)
final class FirestoreProductImportTemplateDataSource
    implements ProductImportTemplateDataSource {
  FirestoreProductImportTemplateDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<ProductImportTemplateDto>(
        firestore: firestore,
        collectionName: 'productImportTemplates',
        converter: FirestoreConverter<ProductImportTemplateDto>(
          fromJson: (data, id) =>
              ProductImportTemplateDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  static const int _maxResultsPerQuery = 100;

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<ProductImportTemplateDto> _collection;

  @override
  Future<List<ProductImportTemplateDto>> listByOrganization({
    required String organizationId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: _maxResultsPerQuery,
      queryBuilder: (query) => query.orderBy('name'),
    );
    return page.items;
  }

  @override
  Future<void> save(ProductImportTemplateDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> delete({
    required String organizationId,
    required String id,
  }) async {
    // A mapping template carries no financial/audit value once removed —
    // same reasoning as `FirestoreCustomerImportTemplateDataSource.delete`.
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('productImportTemplates')
        .doc(id)
        .delete();
  }
}
