/// One row of the Product Dashboard's ranking table (TASK-137, seção 12.1/
/// 12.3 de `tasks.md`: "análise de mix, giro e desempenho por produto"/
/// "ordenação") — one product's worth of quantity/revenue/discount for the
/// filtered period, built exclusively by `LoadProductDashboardRankingUseCase`
/// from `AggregationSnapshot` rows `AggregationRepository` already computed
/// (TASK-133, `productMonthly`) — never a client-side scan of raw orders.
final class ProductDashboardRankingRow {
  const ProductDashboardRankingRow({
    required this.productId,
    required this.productName,
    this.categoryId,
    this.categoryName,
    this.collectionId,
    this.collectionName,
    required this.quantitySold,
    required this.revenueGross,
    required this.revenueNet,
    required this.discountAmount,
    required this.orderCount,
    required this.mixPercentage,
  });

  /// The exact id a drill-down into the product's own detail (TASK-078)
  /// expects.
  final String productId;

  /// Denormalized display label (`AggregationSnapshot.labels['productName']`)
  /// — falls back to [productId] itself when no label was denormalized (e.g.
  /// a product deleted after the snapshot was written).
  final String productName;

  final String? categoryId;
  final String? categoryName;
  final String? collectionId;
  final String? collectionName;

  final int quantitySold;
  final double revenueGross;
  final double revenueNet;
  final double discountAmount;
  final int orderCount;

  /// This product's `revenueNet` share of the total `revenueNet` of every
  /// row in the same filtered set (before a coleção/categoria filter narrows
  /// which rows are shown — see `LoadProductDashboardRankingUseCase`'s own
  /// docs for why), `0`–`100`. The retail "mix" reading of the KPI this
  /// task's own escopo técnico names ("mix médio") — participação do produto
  /// no faturamento do período — computed entirely from
  /// already-fetched/already-bounded rows, never a second read.
  final double mixPercentage;

  /// `discountAmount / revenueGross * 100`, `0` when [revenueGross] is `0`
  /// (never a `NaN`/`Infinity` division by zero).
  double get discountPercentage =>
      revenueGross == 0 ? 0 : (discountAmount / revenueGross) * 100;

  double get averageTicket => orderCount == 0 ? 0 : revenueNet / orderCount;

  /// Always `null` today: "produtos com maior conversão" (this task's own
  /// escopo técnico) requires a ratio of visualizações/adições ao pedido que
  /// resultaram em pedido submetido — no event/aggregation pipeline anywhere
  /// in the codebase tracks product views or catalog add-to-order actions
  /// per period (`AnalyticsEvents` logs them to Firebase Analytics only, an
  /// export sink this app's own domain layer never reads back from). Per
  /// this task's own "Regras de negócio e restrições" ("nunca calculada
  /// ad-hoc no cliente"), this field is never fabricated from a proxy metric
  /// — it stays `null`/"indisponível hoje" until a dedicated tracking +
  /// TASK-133-equivalent aggregation dimension exists. Documented in
  /// `docs/tasks/TASK-137-implementar-dashboard-de-produtos-CONCLUIDA.md`.
  final double? conversionRate = null;

  @override
  bool operator ==(Object other) {
    return other is ProductDashboardRankingRow &&
        productId == other.productId &&
        productName == other.productName &&
        categoryId == other.categoryId &&
        categoryName == other.categoryName &&
        collectionId == other.collectionId &&
        collectionName == other.collectionName &&
        quantitySold == other.quantitySold &&
        revenueGross == other.revenueGross &&
        revenueNet == other.revenueNet &&
        discountAmount == other.discountAmount &&
        orderCount == other.orderCount &&
        mixPercentage == other.mixPercentage;
  }

  @override
  int get hashCode => Object.hash(
    productId,
    productName,
    categoryId,
    categoryName,
    collectionId,
    collectionName,
    quantitySold,
    revenueGross,
    revenueNet,
    discountAmount,
    orderCount,
    mixPercentage,
  );
}
