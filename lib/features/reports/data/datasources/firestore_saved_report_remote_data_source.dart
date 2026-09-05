import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/saved_report_dto.dart';
import 'saved_report_remote_data_source.dart';

/// Firestore-backed [SavedReportRemoteDataSource] for
/// `organizations/{organizationId}/savedReports` (TASK-145).
///
/// Composes [FirestoreCollectionDataSource] like every other Firestore
/// datasource in this codebase instead of calling `cloud_firestore`
/// directly. [listOwned]/[listNonPrivate] fetch a single, generously-sized
/// page (no cursor pagination) — acceptable while a user's/organization's
/// saved report count stays in the dozens, not thousands; revisit with real
/// `getPage` cursoring if that ever changes.
@LazySingleton(as: SavedReportRemoteDataSource)
final class FirestoreSavedReportRemoteDataSource
    implements SavedReportRemoteDataSource {
  FirestoreSavedReportRemoteDataSource(FirebaseFirestore firestore)
    : _firestore = firestore,
      _collection = FirestoreCollectionDataSource<SavedReportDto>(
        firestore: firestore,
        collectionName: 'savedReports',
        converter: FirestoreConverter<SavedReportDto>(
          fromJson: (data, id) => SavedReportDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  static const int _maxResultsPerQuery = 200;

  final FirebaseFirestore _firestore;
  final FirestoreCollectionDataSource<SavedReportDto> _collection;

  @override
  Future<List<SavedReportDto>> listOwned({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: _maxResultsPerQuery,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('ownerId', isEqualTo: userId),
    );
    return page.items;
  }

  @override
  Future<List<SavedReportDto>> listNonPrivate({
    required String organizationId,
    required String companyId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: _maxResultsPerQuery,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('visibility', whereIn: <String>['team', 'organization']),
    );
    return page.items;
  }

  @override
  Future<void> create(SavedReportDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> update(SavedReportDto dto) => _collection.set(
    organizationId: dto.organizationId,
    id: dto.id,
    value: dto,
  );

  @override
  Future<void> delete({
    required String organizationId,
    required String id,
  }) async {
    // A saved view carries no financial/audit value once removed (same
    // reasoning as `FirestoreFavoriteRemoteDataSource.delete`): a hard
    // delete, not `FirestoreCollectionDataSource.softDelete`.
    await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('savedReports')
        .doc(id)
        .delete();
  }
}
