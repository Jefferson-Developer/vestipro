import 'variant_stock_balance.dart';

final class VariantInventoryAvailability {
  const VariantInventoryAvailability({
    required this.variantId,
    required this.productId,
    required this.totalSellableQuantity,
    required this.byWarehouse,
  });

  final String variantId;
  final String productId;
  final int totalSellableQuantity;
  final List<VariantStockBalance> byWarehouse;
}
