import 'inventory_dashboard_stalled_product_row.dart';

/// One cursor-paginated page of [InventoryDashboardStalledProductRow]s,
/// returned by `LoadInventoryDashboardStalledProductsUseCase` — mirrors
/// `ProductCatalogPage`'s own cursor-based shape (never offset/page-number
/// based), since it is built directly from one `ProductRepository
/// .listCatalog` page.
final class InventoryDashboardStalledProductPage {
  const InventoryDashboardStalledProductPage({
    required this.rows,
    required this.hasMore,
    this.nextCursor,
  });

  final List<InventoryDashboardStalledProductRow> rows;
  final bool hasMore;
  final String? nextCursor;

  int get stalledCount => rows.where((row) => row.isStalled).length;
}
