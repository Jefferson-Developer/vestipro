import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/customer_import_template_dto.dart';
import 'customer_import_template_data_source.dart';

/// Firestore-backed [CustomerImportTemplateDataSource] for
/// `organizations/{organizationId}/customerImportTemplates` (TASK-167).
@LazySingleton(as: CustomerImportTemplateDataSource)
final class FirestoreCustomerImportTemplateDataSource
    implements CustomerImportTemplateDataSource {
  FirestoreCustomerImportTemplateDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<CustomerImportTemplateDto>(
        firestore: firestore,
        collectionName: 'customerImportTemplates',
        converter: FirestoreConverter<CustomerImportTemplateDto>(
          fromJson: (data, id) =>
              CustomerImportTemplateDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  static const int _maxResultsPerQuery = 100;

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<CustomerImportTemplateDto> _collection;

  @override
  Future<List<CustomerImportTemplateDto>> listByOrganization({
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
  Future<void> save(CustomerImportTemplateDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> delete({
    required String organizationId,
    required String id,
  }) async {
    // A mapping template carries no financial/audit value once removed
    // (same reasoning as `FirestoreSavedReportRemoteDataSource.delete`): a
    // hard delete, not `FirestoreCollectionDataSource.softDelete`.
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('customerImportTemplates')
        .doc(id)
        .delete();
  }
}
