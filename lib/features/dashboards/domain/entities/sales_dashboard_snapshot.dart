import 'executive_dashboard_trend_point.dart';
import 'sales_dashboard_kpi.dart';

/// Every KPI the Sales Dashboard (TASK-135, seção 12.2 de `tasks.md`)
/// renders for one `SalesDashboardFilters` scope/period: "análise detalhada
/// de pedidos e faturamento, com comparação temporal" — assembled by
/// `LoadSalesDashboardSnapshotUseCase` exclusively from TASK-133's
/// aggregation layer.
///
/// Each field degrades independently, same "um KPI falha e os demais
/// continuam exibidos" contract `ExecutiveDashboardSnapshot` already
/// establishes.
final class SalesDashboardSnapshot {
  const SalesDashboardSnapshot({
    required this.revenue,
    required this.orders,
    required this.averageTicket,
    required this.itemQuantity,
    required this.discountAverage,
    required this.margin,
    required this.piecesPerOrder,
    required this.productsPerOrder,
    required this.revenueTrend,
  });

  /// Faturamento líquido do período (soma de `AggregationSnapshot
  /// .revenueNet`, `salesDaily`).
  final SalesDashboardKpi revenue;

  /// Quantidade de pedidos do período (soma de `AggregationSnapshot
  /// .orderCount`).
  final SalesDashboardKpi orders;

  /// `revenue / orders` do período (nunca uma média de médias).
  final SalesDashboardKpi averageTicket;

  /// Quantidade de itens vendidos no período (soma de `AggregationSnapshot
  /// .itemQuantity`).
  final SalesDashboardKpi itemQuantity;

  /// `discountAmount / revenueGross` do período, em percentual — somado
  /// exclusivamente a partir do `discountAmount`/`revenueGross` que o motor
  /// de precificação (TASK-088) já gravou em cada pedido e que TASK-133 já
  /// agregou; nunca um desconto recalculado nesta camada.
  final SalesDashboardKpi discountAverage;

  /// Sempre [SalesDashboardKpi.notCalculated]: ver
  /// [SalesDashboardKpiStatus.notCalculated] para o motivo (nenhum custo de
  /// produto/margem existe hoje em nenhuma camada do backend).
  final SalesDashboardKpi margin;

  /// `itemQuantity / orders` do período.
  final SalesDashboardKpi piecesPerOrder;

  /// Sempre [SalesDashboardKpi.notCalculated]: ver
  /// [SalesDashboardKpiStatus.notCalculated] para o motivo (nenhuma
  /// dimensão de agregação registra a composição de SKUs distintos por
  /// pedido).
  final SalesDashboardKpi productsPerOrder;

  /// Um ponto por dia do mês filtrado (`salesDaily`, TASK-133) — a
  /// tendência resumida (sparkline) do card de faturamento. Lista vazia
  /// significa "sem dados ainda para nenhum dia do período", nunca uma
  /// falha.
  final List<ExecutiveDashboardTrendPoint> revenueTrend;
}
