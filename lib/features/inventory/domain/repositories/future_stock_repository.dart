import '../entities/future_stock_entry.dart';

abstract interface class FutureStockRepository {
  Future<List<FutureStockEntry>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  });

  Future<List<FutureStockEntry>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  });
}
