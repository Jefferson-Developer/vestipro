import '../value_objects/future_stock_source.dart';

final class FutureStockEntry {
  const FutureStockEntry({
    required this.variantId,
    required this.productId,
    required this.quantity,
    required this.expectedDate,
    required this.source,
    this.warehouseId,
  });

  final String variantId;
  final String productId;
  final String? warehouseId;
  final int quantity;
  final DateTime expectedDate;
  final FutureStockSource source;
}
