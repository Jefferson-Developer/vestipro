import 'aggregation_dimension.dart';

/// The four grouping breakdowns the Sales Dashboard (TASK-135, seção 12.3 de
/// `tasks.md`: "agrupamento") offers for its drill-down table — exactly the
/// three this task's own Critérios de aceite name ("Agrupamento por
/// vendedor, cliente e produto/categoria") plus [category], a client-side
/// re-aggregation of [product] rows (see
/// [SalesDashboardGroupDimension.aggregationDimension]'s own docs), never a
/// sixth server-side dimension of its own.
enum SalesDashboardGroupDimension { seller, customer, product, category }

extension SalesDashboardGroupDimensionMapping on SalesDashboardGroupDimension {
  /// Which TASK-133 [AggregationDimension] this grouping reads from.
  /// [SalesDashboardGroupDimension.category] deliberately maps to the same
  /// [AggregationDimension.productMonthly] as [SalesDashboardGroupDimension
  /// .product]: TASK-133 never modeled a sixth "por categoria" collection —
  /// `productMonthly` already carries `categoryId`/`categoryName` as
  /// denormalized [AggregationSnapshot.labels] precisely so a caller can
  /// re-group those same rows by category client-side (a bounded fold over
  /// an already-bounded read, never a second server round-trip nor a raw
  /// `orders`/`products` scan).
  AggregationDimension get aggregationDimension => switch (this) {
    SalesDashboardGroupDimension.seller => AggregationDimension.sellerMonthly,
    SalesDashboardGroupDimension.customer =>
      AggregationDimension.customerMonthly,
    SalesDashboardGroupDimension.product ||
    SalesDashboardGroupDimension.category =>
      AggregationDimension.productMonthly,
  };

  /// The query-parameter code for this dimension — see
  /// [SalesDashboardFilters.toQueryParameters]/`.fromQueryParameters`.
  String get code => switch (this) {
    SalesDashboardGroupDimension.seller => 'seller',
    SalesDashboardGroupDimension.customer => 'customer',
    SalesDashboardGroupDimension.product => 'product',
    SalesDashboardGroupDimension.category => 'category',
  };

  static SalesDashboardGroupDimension fromCode(String? code) {
    for (final dimension in SalesDashboardGroupDimension.values) {
      if (dimension.code == code) return dimension;
    }
    return SalesDashboardGroupDimension.seller;
  }
}
