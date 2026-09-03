import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../domain/value_objects/aggregation_dimension.dart';
import '../dtos/aggregation_snapshot_dto.dart';
import 'aggregation_remote_data_source.dart';

/// Composite Firestore doc id — must match `buildAggregateDocId` in
/// `functions/src/aggregations/aggregation-shared.ts` exactly, since it is
/// how the client looks up the very same snapshot the Cloud Functions in
/// `functions/src/aggregations` wrote.
String buildAggregationDocId({
  required String companyId,
  required String scopeId,
  required String periodKey,
}) => '${companyId}_${scopeId}_$periodKey';

@LazySingleton(as: AggregationRemoteDataSource)
final class FirestoreAggregationDataSource
    implements AggregationRemoteDataSource {
  FirestoreAggregationDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  FirestoreCollectionDataSource<AggregationSnapshotDto> _collectionFor(
    AggregationDimension dimension,
  ) {
    return FirestoreCollectionDataSource<AggregationSnapshotDto>(
      firestore: _firestore,
      collectionName: dimension.collectionName,
      converter: FirestoreConverter<AggregationSnapshotDto>(
        fromJson: (data, id) =>
            AggregationSnapshotDto.fromJson(data, id: id, dimension: dimension),
        // Read-only collection (Firestore Rules deny every client write —
        // `firestore.rules`, `allow create, update, delete: if false` on
        // every one of the five `*Aggregates` collections); no code path in
        // this datasource ever calls `FirestoreCollectionDataSource.set`/
        // `.update`, so this only exists to satisfy `FirestoreConverter`'s
        // required parameter.
        toJson: (_) => throw UnsupportedError(
          'Aggregation snapshots are server-generated and read-only; the '
          'client never writes to a "*Aggregates" collection.',
        ),
      ),
    );
  }

  @override
  Future<AggregationSnapshotDto?> getById({
    required String organizationId,
    required AggregationDimension dimension,
    required String docId,
  }) {
    return _collectionFor(
      dimension,
    ).getById(organizationId: organizationId, id: docId);
  }

  @override
  Future<List<AggregationSnapshotDto>> listByPeriod({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String periodKey,
    required int limit,
  }) async {
    final page = await _collectionFor(dimension).getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('periodKey', isEqualTo: periodKey),
    );
    return page.items;
  }

  @override
  Future<List<AggregationSnapshotDto>> listByPeriodRange({
    required String organizationId,
    required AggregationDimension dimension,
    required String companyId,
    required String scopeId,
    required String fromPeriodKey,
    required String toPeriodKey,
  }) async {
    // A trend chart of one scope across a date range is a small, explicitly
    // bounded read (`salesDaily` at most one row per calendar day) — 400
    // comfortably covers a year plus margin, still far from an unbounded
    // "whole collection" read.
    final page = await _collectionFor(dimension).getPage(
      organizationId: organizationId,
      limit: 400,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('scopeId', isEqualTo: scopeId)
          .where('periodKey', isGreaterThanOrEqualTo: fromPeriodKey)
          .where('periodKey', isLessThanOrEqualTo: toPeriodKey)
          .orderBy('periodKey'),
    );
    return page.items;
  }
}
