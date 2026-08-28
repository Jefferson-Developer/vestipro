import '../../../../core/utils/utils.dart';
import '../entities/variant_inventory_availability.dart';
import '../entities/variant_stock_balance.dart';

abstract interface class VariantStockBalanceRepository {
  Future<AppResult<List<VariantStockBalance>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  });

  Future<AppResult<List<VariantStockBalance>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  });

  Future<AppResult<List<VariantStockBalance>>> listByWarehouse({
    required String organizationId,
    required String warehouseId,
    int limit = 20,
    String? startAfterId,
  });

  Future<AppResult<VariantInventoryAvailability>> getAvailability({
    required String organizationId,
    required String variantId,
    String? warehouseId,
  });
}
