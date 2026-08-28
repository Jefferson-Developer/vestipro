import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../dtos/variant_stock_balance_dto.dart';
import 'variant_stock_balance_remote_data_source.dart';

@LazySingleton(as: VariantStockBalanceRemoteDataSource)
final class FirestoreVariantStockBalanceDataSource
    implements VariantStockBalanceRemoteDataSource {
  FirestoreVariantStockBalanceDataSource(FirebaseFirestore firestore)
    : _collection = FirestoreCollectionDataSource<VariantStockBalanceDto>(
        firestore: firestore,
        collectionName: 'inventory',
        converter: FirestoreConverter<VariantStockBalanceDto>(
          fromJson: (data, id) => VariantStockBalanceDto.fromJson(data, id: id),
          toJson: (dto) => dto.toJson(),
        ),
      );

  final FirestoreCollectionDataSource<VariantStockBalanceDto> _collection;

  @override
  Future<List<VariantStockBalanceDto>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  }) async {
    final ids = productIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const <VariantStockBalanceDto>[];
    final results = <VariantStockBalanceDto>[];
    for (final chunk in _chunk(ids, 10)) {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: 200,
        queryBuilder: (query) => query.where('productId', whereIn: chunk),
      );
      results.addAll(page.items);
    }
    return results;
  }

  @override
  Future<List<VariantStockBalanceDto>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  }) async {
    final ids = variantIds.toSet().toList(growable: false);
    if (ids.isEmpty) return const <VariantStockBalanceDto>[];
    final results = <VariantStockBalanceDto>[];
    for (final chunk in _chunk(ids, 10)) {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: 200,
        queryBuilder: (query) => query.where('variantId', whereIn: chunk),
      );
      results.addAll(page.items);
    }
    return results;
  }

  @override
  Future<List<VariantStockBalanceDto>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  }) async {
    final page = await _collection.getPage(
      organizationId: organizationId,
      limit: limit,
      queryBuilder: (query) {
        var scoped = query
            .where('warehouseId', isEqualTo: warehouseId)
            .orderBy('variantId')
            .orderBy('updatedAt', descending: true);
        if (startAfterId != null && startAfterId.isNotEmpty) {
          scoped = scoped.where('variantId', isGreaterThan: startAfterId);
        }
        return scoped;
      },
    );
    return page.items;
  }

  Iterable<List<String>> _chunk(List<String> ids, int size) sync* {
    for (var index = 0; index < ids.length; index += size) {
      final end = (index + size) > ids.length ? ids.length : index + size;
      yield ids.sublist(index, end);
    }
  }
}
