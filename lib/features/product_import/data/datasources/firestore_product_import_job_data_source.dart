import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/product_import_job_dto.dart';
import 'product_import_job_data_source.dart';

/// Firestore-backed [ProductImportJobDataSource] for
/// `organizations/{organizationId}/productImportJobs` (TASK-168) — read
/// only, see that interface's docs for why.
@LazySingleton(as: ProductImportJobDataSource)
final class FirestoreProductImportJobDataSource
    implements ProductImportJobDataSource {
  FirestoreProductImportJobDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<ProductImportJobDto>(
        firestore: firestore,
        collectionName: 'productImportJobs',
        converter: FirestoreConverter<ProductImportJobDto>(
          fromJson: (data, id) => ProductImportJobDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<ProductImportJobDto> _collection;

  @override
  Stream<ProductImportJobDto?> watchJob({
    required String organizationId,
    required String jobId,
  }) {
    return _collection.getStream(organizationId: organizationId, id: jobId);
  }

  @override
  Future<List<ProductImportJobDto>> listByOrganization({
    required String organizationId,
    required int limit,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) => query.orderBy('createdAt', descending: true),
    );
    return page.items;
  }
}
