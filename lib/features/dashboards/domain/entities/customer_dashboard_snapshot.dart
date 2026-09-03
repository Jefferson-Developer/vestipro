import 'executive_dashboard_metric.dart';

/// Every KPI the Customer Dashboard (TASK-136, seção 12.1/12.2 de
/// `tasks.md`) renders for one [CustomerDashboardFilters] scope/period,
/// assembled by `LoadCustomerDashboardSnapshotUseCase` exclusively from
/// already-server-computed contracts: TASK-133's `AggregationRepository`
/// (`customerMonthly`) and TASK-117's `PositivacaoRepository` — never a
/// client-side sum of raw `orders`/`customers` documents.
///
/// Each field is independent: a failure resolving one never blocks the
/// others ("um KPI falha e os demais continuam exibidos"), same contract
/// `ExecutiveDashboardSnapshot`/`SalesDashboardSnapshot` already set.
final class CustomerDashboardSnapshot {
  const CustomerDashboardSnapshot({
    required this.activeCustomers,
    required this.newCustomers,
    required this.reactivatedCustomers,
    required this.repurchaseRatePercentage,
    required this.averagePurchaseFrequency,
    required this.churnPercentage,
    required this.portfolioCoverage,
    required this.positivacaoPercentage,
  });

  /// Quantos clientes da carteira compraram no período —
  /// `PositivacaoSnapshot.positivatedCount`, the exact same source/definition
  /// `ExecutiveDashboardSnapshot.activeCustomers` already uses (this task's
  /// own acceptance criterion: "definição de cliente ativo/inativo
  /// consistente" across dashboards).
  final ExecutiveDashboardMetric activeCustomers;

  /// Always [ExecutiveDashboardMetric.notCalculated] today: distinguishing
  /// "cliente que comprou pela primeira vez neste período" from "cliente que
  /// já comprava e voltou a comprar" requires either a `Customer` field this
  /// entity does not carry into any TASK-133 aggregation snapshot (a
  /// "primeira compra em" date) or a full scan of a customer's order
  /// history — the latter forbidden by this task's own "nunca recalculado
  /// do zero no cliente" rule. Same documented gap
  /// `ExecutiveDashboardSnapshot.newCustomers` already carries.
  final ExecutiveDashboardMetric newCustomers;

  /// Always [ExecutiveDashboardMetric.notCalculated] today, for the same
  /// reason as [newCustomers]: telling apart "novo" from "reativado"
  /// requires the customer's full purchase history (when was their very
  /// first order ever), not just the current and previous month's
  /// `customerMonthly` snapshots this dashboard reads.
  final ExecutiveDashboardMetric reactivatedCustomers;

  /// Fração dos clientes ativos no período com **mais de um pedido** dentro
  /// do próprio período (`customerMonthly.orderCount >= 2`) — uma recompra
  /// intra-período, não uma recompra ao longo da vida do cliente (essa
  /// exigiria histórico completo, fora do escopo de `customerMonthly`).
  /// Computado inteiramente a partir dos snapshots pré-calculados já lidos
  /// para o ranking (TASK-133), nunca uma nova varredura de pedidos.
  final ExecutiveDashboardMetric repurchaseRatePercentage;

  /// `soma(customerMonthly.orderCount) / clientes ativos` no período — média
  /// de pedidos por cliente ativo, a mesma dupla de números
  /// (faturamento/pedidos → ticket médio) que `ExecutiveDashboardSnapshot`
  /// já deriva de agregações pré-calculadas, aqui aplicada a pedidos/cliente.
  final ExecutiveDashboardMetric averagePurchaseFrequency;

  /// Fração dos clientes ativos no período anterior que **não** aparecem no
  /// `customerMonthly` do período corrente — um churn período-a-período
  /// derivado inteiramente de dois snapshots pré-calculados (nunca um
  /// recálculo de pedidos brutos). **Divergência documentada**: a regra de
  /// insight de cliente inativo (TASK-122) define inatividade por dias
  /// corridos desde o último pedido (`asOf - lastOrderAt > threshold`), um
  /// dado que não existe em nenhuma dimensão de agregação da TASK-133
  /// (`customerMonthly` não carrega `lastOrderAt`) — replicar literalmente
  /// aquela definição exigiria uma nova dimensão de agregação, fora do
  /// escopo técnico desta task. Esta métrica usa a definição mais próxima
  /// computável a partir do dado já pré-calculado disponível, documentada
  /// aqui e em `docs/tasks/TASK-136-implementar-dashboard-de-clientes-CONCLUIDA.md`.
  final ExecutiveDashboardMetric churnPercentage;

  /// `PositivacaoSnapshot.totalPortfolio` — tamanho da carteira medida no
  /// período (quantos clientes compõem o escopo, não quantos compraram).
  final ExecutiveDashboardMetric portfolioCoverage;

  /// `PositivacaoSnapshot.percentage` — fração da carteira que comprou no
  /// período, a mesma fonte `ExecutiveDashboardSnapshot.positivacaoPercentage`
  /// já usa.
  final ExecutiveDashboardMetric positivacaoPercentage;
}
