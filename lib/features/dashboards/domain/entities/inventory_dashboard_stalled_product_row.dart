import '../../../inventory/domain/entities/stock_turnover_metric_snapshot.dart';

/// One Product's worth of coverage/giro evidence for the Inventory
/// Dashboard's "produtos parados" list (TASK-139), assembled by
/// `LoadInventoryDashboardStalledProductsUseCase` by cruzando uma página
/// paginada de `ProductRepository.listCatalog` com
/// `GetStockTurnoverMetricsUseCase` (`StockTurnoverScopeType.product`,
/// TASK-094) — a mesma (e única) fonte de giro por produto que
/// `ProductDashboardBloc` (TASK-137) já lê para a mesma finalidade de
/// consistência com a regra de insight TASK-128 (ver esse bloc's own doc
/// para a nota completa sobre essa lacuna pré-existente).
final class InventoryDashboardStalledProductRow {
  const InventoryDashboardStalledProductRow({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.categoryId,
    required this.categoryName,
    required this.turnoverSnapshot,
    required this.isStalled,
  });

  final String productId;
  final String productName;
  final String? imageUrl;
  final String? categoryId;
  final String? categoryName;

  /// `null` apenas quando a TASK-094 ainda não produziu um snapshot para
  /// este produto/período (nunca um giro "zerado" fabricado).
  final StockTurnoverMetricSnapshot? turnoverSnapshot;

  /// `true` quando [turnoverSnapshot] existe, seu `coverageStatus` é
  /// `StockCoverageStatus.ready` e `stockCoverageDays` alcança o
  /// `InventoryDashboardFilters.stalledCoverageDaysThreshold` configurado —
  /// nunca fabricado sem esse dado real.
  final bool isStalled;
}
