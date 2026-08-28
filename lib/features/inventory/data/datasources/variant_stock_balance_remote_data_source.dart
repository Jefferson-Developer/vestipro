import '../dtos/variant_stock_balance_dto.dart';

abstract interface class VariantStockBalanceRemoteDataSource {
  Future<List<VariantStockBalanceDto>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  });

  Future<List<VariantStockBalanceDto>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  });

  Future<List<VariantStockBalanceDto>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  });
}
