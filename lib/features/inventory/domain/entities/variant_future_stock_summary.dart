import 'future_stock_entry.dart';

final class VariantFutureStockSummary {
  const VariantFutureStockSummary({
    required this.variantId,
    required this.productId,
    required this.immediateQuantity,
    this.futureEntries = const <FutureStockEntry>[],
  });

  final String variantId;
  final String productId;
  final int immediateQuantity;
  final List<FutureStockEntry> futureEntries;

  int get totalFutureQuantity =>
      futureEntries.fold<int>(0, (sum, entry) => sum + entry.quantity);

  DateTime? get nextExpectedDate =>
      futureEntries.isEmpty ? null : futureEntries.first.expectedDate;
}
