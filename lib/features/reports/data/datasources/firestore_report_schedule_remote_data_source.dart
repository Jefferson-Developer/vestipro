import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/report_schedule_dto.dart';
import 'report_schedule_remote_data_source.dart';

/// Firestore-backed [ReportScheduleRemoteDataSource] for
/// `organizations/{organizationId}/reportSchedules` (TASK-149).
///
/// Composes [FirestoreCollectionDataSource] like every other Firestore
/// datasource in this codebase instead of calling `cloud_firestore`
/// directly. [listByOrganization] fetches a single, generously-sized page
/// (no cursor pagination) — acceptable while an organization's schedule
/// count stays in the dozens, matching [FirestoreSavedReportRemoteDataSource]
/// (TASK-145)'s own precedent.
@LazySingleton(as: ReportScheduleRemoteDataSource)
final class FirestoreReportScheduleRemoteDataSource
    implements ReportScheduleRemoteDataSource {
  FirestoreReportScheduleRemoteDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<ReportScheduleDto>(
        firestore: firestore,
        collectionName: 'reportSchedules',
        converter: FirestoreConverter<ReportScheduleDto>(
          fromJson: (data, id) => ReportScheduleDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  static const int _maxResultsPerQuery = 200;

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<ReportScheduleDto> _collection;

  @override
  Future<List<ReportScheduleDto>> listByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: _maxResultsPerQuery,
      queryBuilder: (query) => query.where('companyId', isEqualTo: companyId),
    );
    return page.items;
  }

  @override
  Future<List<ReportScheduleDto>> listActiveBySavedReportId({
    required String organizationId,
    required String savedReportId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 1,
      queryBuilder: (query) => query
          .where('savedReportId', isEqualTo: savedReportId)
          .where('status', isEqualTo: 'active'),
    );
    return page.items;
  }

  @override
  Future<void> create(ReportScheduleDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> update(ReportScheduleDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> delete({
    required String organizationId,
    required String id,
  }) async {
    // A schedule carries no financial/audit value once removed — same
    // reasoning `FirestoreSavedReportRemoteDataSource.delete` already
    // documents for `savedReports`: a hard delete, not
    // `FirestoreCollectionDataSource.softDelete`. Every delivery it produced
    // stays recorded in `reportScheduleDeliveries` regardless.
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('reportSchedules')
        .doc(id)
        .delete();
  }
}
