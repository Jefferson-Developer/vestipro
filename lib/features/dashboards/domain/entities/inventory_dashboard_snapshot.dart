import '../../../inventory/domain/entities/stock_alert.dart';
import '../../../inventory/domain/value_objects/stock_alert_level.dart';
import 'executive_dashboard_metric.dart';

/// Every KPI card the Inventory Dashboard (TASK-139, seção 12.1 de
/// `tasks.md`) renders for one `InventoryDashboardFilters` scope/period,
/// assembled by `LoadInventoryDashboardSnapshotUseCase` exclusively from
/// TASK-094's `GetStockTurnoverMetricsUseCase` (coverage/sell-through/giro)
/// and TASK-093's `ListStockAlertsUseCase` (alertas de ruptura já gerados,
/// nunca reprocessados/duplicados aqui) — never a raw query against
/// `orders`/`products`/`stockAlerts`.
final class InventoryDashboardSnapshot {
  const InventoryDashboardSnapshot({
    required this.coverageDays,
    required this.sellThroughRate,
    required this.turnoverRate,
    required this.warehousesConsidered,
    required this.alerts,
    required this.alertsHasMore,
    required this.generatedAt,
  });

  /// `StockTurnoverMetricSnapshot.stockCoverageDays` (TASK-094) do escopo
  /// resolvido (depósito, coleção, ou média ponderada entre todo depósito
  /// ativo — ver `InventoryDashboardFilters`'s own doc). `notCalculated`
  /// quando o gerador noturno da TASK-094 ainda não produziu um snapshot
  /// para o escopo/período (nunca `0`, que seria indistinguível de uma
  /// cobertura real de zero dias).
  final ExecutiveDashboardMetric coverageDays;

  /// `StockTurnoverMetricSnapshot.sellThroughRate * 100` do escopo
  /// resolvido — mesma convenção de "0-100" que `CollectionDashboardEntry
  /// .sellThrough` já usa (TASK-138).
  final ExecutiveDashboardMetric sellThroughRate;

  /// `StockTurnoverMetricSnapshot.turnoverRate` do escopo resolvido — índice
  /// bruto, sem conversão percentual, mesma convenção que
  /// `ProductDashboardPage`'s tabela de giro já usa (TASK-137).
  final ExecutiveDashboardMetric turnoverRate;

  /// Quantos depósitos ativos foram lidos e dobrados (média ponderada) para
  /// compor [coverageDays]/[sellThroughRate]/[turnoverRate] quando nenhum
  /// `warehouseId`/`collectionId` foi selecionado nos filtros — `0` quando
  /// um escopo único (um depósito ou uma coleção) foi lido diretamente, sem
  /// fold algum. Puramente informativo para a UI explicar "agregado sobre N
  /// depósitos".
  final int warehousesConsidered;

  /// Alertas de ruptura ativos (TASK-093), consolidados aqui sem duplicar
  /// nem reprocessar estado: a mesma entidade `StockAlert` e a mesma
  /// primeira página de `ListStockAlertsUseCase` que `StockAlertsPage`
  /// (TASK-093) já exibe, apenas re-renderizada num card resumido — nunca
  /// uma segunda fonte de verdade sobre "quais alertas estão ativos".
  final List<StockAlert> alerts;

  /// Whether more alerts exist beyond [alerts] (a bounded first page) — a
  /// "ver todos os alertas" affordance é oferecida em vez de tentar carregar
  /// tudo de uma vez (mesma "nunca centenas de queries do cliente" bound de
  /// `tasks.md`, seção 22).
  final bool alertsHasMore;

  final DateTime generatedAt;

  int get activeAlertCount => alerts.length;

  int get criticalAlertCount =>
      alerts.where((alert) => alert.level == StockAlertLevel.critical).length;
}
