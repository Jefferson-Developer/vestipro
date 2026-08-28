import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/stock_alert_dto.dart';
import 'stock_alert_data_source.dart';

@LazySingleton(as: StockAlertDataSource)
final class FirestoreStockAlertDataSource implements StockAlertDataSource {
  FirestoreStockAlertDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<StockAlertDto>(
        firestore: firestore,
        collectionName: 'stockAlerts',
        converter: FirestoreConverter<StockAlertDto>(
          fromJson: (data, id) => StockAlertDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<StockAlertDto> _collection;

  @override
  Future<List<StockAlertDto>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    String? level,
    String? productId,
    String? warehouseId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query.orderBy('triggeredAt', descending: true);
        if (level != null && level.isNotEmpty) {
          scoped = scoped.where('level', isEqualTo: level);
        }
        if (productId != null && productId.isNotEmpty) {
          scoped = scoped.where('productId', isEqualTo: productId);
        }
        if (warehouseId != null && warehouseId.isNotEmpty) {
          scoped = scoped.where('warehouseId', isEqualTo: warehouseId);
        }
        if (before != null) {
          scoped = scoped.where(
            'triggeredAt',
            isLessThan: Timestamp.fromDate(before),
          );
        }
        return scoped;
      },
    );
    return page.items;
  }
}
