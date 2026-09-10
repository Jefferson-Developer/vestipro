import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/nps_aggregate_snapshot_dto.dart';
import 'nps_aggregate_data_source.dart';

@LazySingleton(as: NpsAggregateDataSource)
final class FirestoreNpsAggregateDataSource implements NpsAggregateDataSource {
  FirestoreNpsAggregateDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collectionName = 'npsMonthlyAggregates';

  late final FirestoreCollectionDataSource<NpsAggregateSnapshotDto>
  _collection = FirestoreCollectionDataSource<NpsAggregateSnapshotDto>(
    firestore: _firestore,
    collectionName: _collectionName,
    converter: FirestoreConverter<NpsAggregateSnapshotDto>(
      fromJson: (data, id) => NpsAggregateSnapshotDto.fromJson(data, id: id),
      // Read-only collection (Firestore Rules deny every client write) — no
      // code path here ever calls `.set`/`.update`, this only satisfies
      // `FirestoreConverter`'s required parameter (same trade-off
      // `FirestoreAggregationDataSource` already accepts).
      toJson: (_) => throw UnsupportedError(
        'NPS aggregate snapshots are server-generated and read-only; the '
        'client never writes to "npsMonthlyAggregates".',
      ),
    ),
  );

  @override
  Future<NpsAggregateSnapshotDto?> getById({
    required String organizationId,
    required String docId,
  }) {
    return _collection.getById(organizationId: organizationId, id: docId);
  }
}
