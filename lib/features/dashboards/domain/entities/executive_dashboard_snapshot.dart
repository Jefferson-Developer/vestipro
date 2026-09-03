import 'executive_dashboard_metric.dart';
import 'executive_dashboard_trend_point.dart';

/// Every KPI the Executive Dashboard (TASK-134, seção 12.2 de `tasks.md`)
/// renders for one [ExecutiveDashboardFilters] scope/period, assembled by
/// `LoadExecutiveDashboardSnapshotUseCase` from TASK-133's aggregation layer
/// plus the already-existing TASK-116 (`Target`/`TargetAchievementRepository`)
/// and TASK-117 (`PositivacaoRepository`) snapshot contracts.
///
/// Each field is independent: a failure resolving one (e.g. no `Target`
/// cadastrada for this scope) never blocks the others — see
/// [ExecutiveDashboardMetric]'s own status docs.
final class ExecutiveDashboardSnapshot {
  const ExecutiveDashboardSnapshot({
    required this.revenue,
    required this.orders,
    required this.averageTicket,
    required this.activeCustomers,
    required this.newCustomers,
    required this.positivacaoPercentage,
    required this.targetAchievementPercentage,
    required this.revenueGrowthMoM,
    required this.revenueGrowthYoY,
    required this.revenueTrend,
  });

  /// Faturamento líquido do período (soma de `AggregationSnapshot.revenueNet`).
  final ExecutiveDashboardMetric revenue;

  /// Quantidade de pedidos do período (soma de
  /// `AggregationSnapshot.orderCount`).
  final ExecutiveDashboardMetric orders;

  /// `revenue / orders` do período (nunca uma média de médias).
  final ExecutiveDashboardMetric averageTicket;

  /// Quantos clientes da carteira compraram no período —
  /// `PositivacaoSnapshot.positivatedCount`, a contagem absoluta (distinta de
  /// [positivacaoPercentage], que é a fração da carteira total).
  final ExecutiveDashboardMetric activeCustomers;

  /// Sempre [ExecutiveDashboardMetric.notCalculated] hoje: nenhuma dimensão
  /// de agregação da TASK-133 (nem `Customer.createdAt`, uma data de
  /// cadastro, não de "primeira compra") permite distinguir "cliente que
  /// comprou pela primeira vez neste período" sem escanear o histórico
  /// completo de pedidos do cliente no cliente (o que a própria task
  /// proíbe: "Dashboard nunca executa cálculo pesado no cliente"). Exibido
  /// mesmo assim (nunca omitido) para deixar explícito que o dado ainda não
  /// existe, nunca como `0` — mesmo padrão de UX já usado por
  /// `PositivacaoSnapshot.notCalculated`/`TargetAchievementSnapshot`
  /// (`realizedValue == null`). Documentado como pendência em
  /// `docs/tasks/TASK-134-implementar-dashboard-executivo-CONCLUIDA.md` para
  /// uma futura extensão da agregação (`customerMonthly` ganhando um
  /// `firstPurchaseMonth`, ou uma nova dimensão dedicada).
  final ExecutiveDashboardMetric newCustomers;

  /// `PositivacaoSnapshot.percentage` — fração da carteira total que
  /// comprou no período.
  final ExecutiveDashboardMetric positivacaoPercentage;

  /// `TargetProgressViewModel.achievementPercentage` da meta de faturamento
  /// vigente para este escopo (empresa ou equipe), quando uma `Target`
  /// cadastrada cobre o período filtrado — [ExecutiveDashboardMetric
  /// .notCalculated] quando não há meta cadastrada ou a meta ainda não tem
  /// `TargetAchievementSnapshot` calculado, nunca `0%`.
  final ExecutiveDashboardMetric targetAchievementPercentage;

  /// Variação percentual do faturamento vs. o mês calendário anterior —
  /// `null` (via [ExecutiveDashboardMetric.notCalculated]) quando o mês
  /// anterior não tem nenhum dado ainda (organização nova).
  final ExecutiveDashboardMetric revenueGrowthMoM;

  /// Variação percentual do faturamento vs. o mesmo mês do ano anterior.
  final ExecutiveDashboardMetric revenueGrowthYoY;

  /// Um ponto por dia do mês filtrado (`salesDaily`, TASK-133) — a
  /// tendência resumida (sparkline) do card de faturamento. Lista vazia
  /// significa "sem dados ainda para nenhum dia do período", nunca uma
  /// falha (`AppManagementChart` já trata lista vazia como estado vazio).
  final List<ExecutiveDashboardTrendPoint> revenueTrend;
}
