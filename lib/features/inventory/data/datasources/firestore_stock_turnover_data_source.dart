import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/stock_turnover_metric_snapshot_dto.dart';
import 'stock_turnover_data_source.dart';

@LazySingleton(as: StockTurnoverDataSource)
final class FirestoreStockTurnoverDataSource
    implements StockTurnoverDataSource {
  FirestoreStockTurnoverDataSource(FirebaseFirestore firestore)
    : _collection =
          FirestoreCollectionDataSource<StockTurnoverMetricSnapshotDto>(
            firestore: firestore,
            collectionName: 'stockTurnoverMetrics',
            converter: FirestoreConverter<StockTurnoverMetricSnapshotDto>(
              fromJson: (data, id) =>
                  StockTurnoverMetricSnapshotDto.fromJson(data, id: id),
              toJson: (dto) => dto.toJson(),
            ),
          );

  final FirestoreCollectionDataSource<StockTurnoverMetricSnapshotDto>
  _collection;

  @override
  Future<StockTurnoverMetricSnapshotDto?> getByScopeAndPeriod({
    required String organizationId,
    required String scopeType,
    required String scopeId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: 1,
      queryBuilder: (query) => query
          .where('scopeType', isEqualTo: scopeType)
          .where('scopeId', isEqualTo: scopeId)
          .where('periodStart', isEqualTo: Timestamp.fromDate(periodStart))
          .where('periodEnd', isEqualTo: Timestamp.fromDate(periodEnd))
          .orderBy('generatedAt', descending: true),
    );
    if (page.items.isEmpty) {
      return null;
    }
    return page.items.first;
  }
}
