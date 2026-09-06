import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/customer_import_job_dto.dart';
import 'customer_import_job_data_source.dart';

/// Firestore-backed [CustomerImportJobDataSource] for
/// `organizations/{organizationId}/customerImportJobs` (TASK-167) — read
/// only, see that interface's docs for why.
@LazySingleton(as: CustomerImportJobDataSource)
final class FirestoreCustomerImportJobDataSource
    implements CustomerImportJobDataSource {
  FirestoreCustomerImportJobDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<CustomerImportJobDto>(
        firestore: firestore,
        collectionName: 'customerImportJobs',
        converter: FirestoreConverter<CustomerImportJobDto>(
          fromJson: (data, id) => CustomerImportJobDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<CustomerImportJobDto> _collection;

  @override
  Stream<CustomerImportJobDto?> watchJob({
    required String organizationId,
    required String jobId,
  }) {
    return _collection.getStream(organizationId: organizationId, id: jobId);
  }

  @override
  Future<List<CustomerImportJobDto>> listByOrganization({
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
