import 'executive_dashboard_metric.dart';

/// Every KPI card the Product Dashboard (TASK-137, seção 12.1/12.2 de
/// `tasks.md`) renders for one [ProductDashboardFilters] scope/period,
/// assembled by `BuildProductDashboardSnapshotUseCase` as a pure,
/// synchronous fold over the exact same `List<ProductDashboardRankingRow>`
/// `LoadProductDashboardRankingUseCase` already fetched for the ranking
/// table — never a second read, and never a value that could disagree with
/// what the ranking table itself shows for the same filtered scope.
final class ProductDashboardSnapshot {
  const ProductDashboardSnapshot({
    required this.quantitySold,
    required this.activeProductCount,
    required this.averageDiscountPercentage,
    required this.margin,
  });

  /// Soma de `ProductDashboardRankingRow.quantitySold` do escopo filtrado.
  final ExecutiveDashboardMetric quantitySold;

  /// Quantidade de produtos distintos com venda no período filtrado — a
  /// leitura de "mix" deste dashboard como amplitude de sortimento
  /// comercializado (quantos SKUs/produtos diferentes tiveram saída), a
  /// contraparte de amplitude à participação de faturamento
  /// (`ProductDashboardRankingRow.mixPercentage`) já exposta por linha.
  final ExecutiveDashboardMetric activeProductCount;

  /// `soma(discountAmount) / soma(revenueGross) * 100` do escopo filtrado —
  /// uma média ponderada por faturamento, nunca uma média aritmética simples
  /// de `ProductDashboardRankingRow.discountPercentage` (que sub-pesaria
  /// produtos de alto volume).
  final ExecutiveDashboardMetric averageDiscountPercentage;

  /// Sempre [ExecutiveDashboardMetric.notCalculated]: nenhum campo de
  /// custo existe em `Product` nem em nenhuma dimensão de agregação da
  /// TASK-133 para derivar margem — mesma lacuna documentada em
  /// `SalesDashboardSnapshot.margin` ("Sem dado de custo/margem
  /// disponível"), nunca inventada aqui.
  final ExecutiveDashboardMetric margin;
}
