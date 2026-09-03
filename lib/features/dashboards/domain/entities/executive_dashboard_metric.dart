/// Whether one [ExecutiveDashboardMetric] has a real value to render.
enum ExecutiveDashboardMetricStatus {
  /// [ExecutiveDashboardMetric.value] is a real, server-aggregated number.
  available,

  /// No aggregation pipeline has populated this metric for this
  /// scope/period yet — a real, expected state (e.g. a brand-new
  /// organization, or a metric whose data source `tasks.md`'s own schema
  /// does not model yet, like "clientes novos" — see
  /// `LoadExecutiveDashboardSnapshotUseCase`'s own docs). Never rendered as
  /// zero.
  notCalculated,

  /// The read that would have populated this metric failed (a repository
  /// [Failure]) — kept independent per metric so "um KPI falha e os demais
  /// continuam exibidos" (this task's own testing requirement) holds: one
  /// failed source (e.g. `TargetAchievementRepository`) never blocks
  /// `revenue`/`orders`/... which came from a different, healthy source.
  failed,
}

/// One KPI card's worth of data (TASK-134): the current period's value,
/// optionally the equivalent previous-period value to compute the
/// "comparação com o período anterior" every KPI card must show, and the
/// [status] the presentation layer renders instead of guessing from a
/// `null` value alone.
///
/// Never itself queries anything — every instance is built by
/// `LoadExecutiveDashboardSnapshotUseCase` from a value some repository
/// already resolved (`AggregationRepository`/`PositivacaoRepository`/
/// `TargetAchievementRepository`, all TASK-133/TASK-116/TASK-117 snapshot
/// contracts), never a client-side sum of raw orders/customers.
final class ExecutiveDashboardMetric {
  const ExecutiveDashboardMetric.available({
    required this.value,
    this.previousValue,
  }) : status = ExecutiveDashboardMetricStatus.available,
       failureMessage = null;

  const ExecutiveDashboardMetric.notCalculated()
    : status = ExecutiveDashboardMetricStatus.notCalculated,
      value = null,
      previousValue = null,
      failureMessage = null;

  const ExecutiveDashboardMetric.failed(String message)
    : status = ExecutiveDashboardMetricStatus.failed,
      value = null,
      previousValue = null,
      failureMessage = message;

  final ExecutiveDashboardMetricStatus status;
  final double? value;
  final double? previousValue;
  final String? failureMessage;

  bool get isAvailable => status == ExecutiveDashboardMetricStatus.available;

  /// `(value - previousValue) / previousValue * 100`, or `null` when either
  /// side is unavailable, or when [previousValue] is `0` (never a
  /// `NaN`/`Infinity` division by zero) — the presentation layer renders
  /// `null` as "sem comparação disponível", never as `0%`.
  double? get changePercentage {
    final current = value;
    final previous = previousValue;
    if (current == null || previous == null || previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  @override
  bool operator ==(Object other) {
    return other is ExecutiveDashboardMetric &&
        status == other.status &&
        value == other.value &&
        previousValue == other.previousValue &&
        failureMessage == other.failureMessage;
  }

  @override
  int get hashCode => Object.hash(status, value, previousValue, failureMessage);
}
