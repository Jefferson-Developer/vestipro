/// Whether one [SalesDashboardKpi] has a real value to render — same three
/// states `ExecutiveDashboardMetricStatus` already models, kept as its own
/// enum (not a reuse) only because [SalesDashboardKpi] itself is not a reuse
/// of `ExecutiveDashboardMetric` (see that class's own docs for why: this
/// dashboard needs two simultaneous comparison baselines, MoM and YoY,
/// `ExecutiveDashboardMetric` only ever carries one `previousValue`).
enum SalesDashboardKpiStatus {
  /// [SalesDashboardKpi.value] is a real, server-aggregated number.
  available,

  /// No TASK-133 aggregation dimension (nor the pricing engine, TASK-088)
  /// produces the data this KPI needs yet — always shown as "not
  /// calculated", never as `0`, same convention `ExecutiveDashboardMetric
  /// .notCalculated` already establishes. Used today by
  /// [LoadSalesDashboardSnapshotUseCase] for exactly two KPIs: `margin`
  /// (no `Product.cost`/pricing-engine margin output exists anywhere in the
  /// codebase to read instead of inventing one in the presentation layer,
  /// which this task's own "Regras de negócio e restrições" forbids) and
  /// `productsPerOrder` (no aggregation dimension records distinct-SKU
  /// composition per order — `productMonthly` is aggregated across every
  /// order of a product, not per-order — computing it accurately would
  /// require scanning raw orders client-side, which this task's own scope
  /// técnico forbids: "consulta pontual e limitada, nunca uma varredura
  /// completa").
  notCalculated,

  /// The read that would have populated this KPI failed (a repository
  /// [Failure]) — independent per KPI so one failed source never blocks the
  /// others, same "um KPI falha e os demais continuam exibidos" contract
  /// `ExecutiveDashboardSnapshot` already tests for.
  failed,
}

/// One KPI card's worth of data for the Sales Dashboard (TASK-135): the
/// current period's value plus both the equivalent previous-month
/// ("comparação MoM") and previous-year ("comparação YoY") values — this
/// task's own scope técnico explicitly asks for both simultaneously
/// ("com comparação MoM e YoY"), unlike the Executive Dashboard's KPI cards
/// (`ExecutiveDashboardMetric`, one comparison baseline at a time).
///
/// Never itself queries anything — every instance is built by
/// [LoadSalesDashboardSnapshotUseCase] from [AggregationSnapshot] rows
/// `AggregationRepository` (TASK-133) already computed server-side, never a
/// client-side sum of raw orders.
final class SalesDashboardKpi {
  const SalesDashboardKpi.available({
    required this.value,
    this.previousMonthValue,
    this.previousYearValue,
  }) : status = SalesDashboardKpiStatus.available,
       failureMessage = null;

  const SalesDashboardKpi.notCalculated()
    : status = SalesDashboardKpiStatus.notCalculated,
      value = null,
      previousMonthValue = null,
      previousYearValue = null,
      failureMessage = null;

  const SalesDashboardKpi.failed(String message)
    : status = SalesDashboardKpiStatus.failed,
      value = null,
      previousMonthValue = null,
      previousYearValue = null,
      failureMessage = message;

  final SalesDashboardKpiStatus status;
  final double? value;
  final double? previousMonthValue;
  final double? previousYearValue;
  final String? failureMessage;

  bool get isAvailable => status == SalesDashboardKpiStatus.available;

  /// `(value - previousMonthValue) / previousMonthValue * 100` — "variação
  /// percentual" of the MoM comparison (seção 12.3: "comparação de período
  /// ... com variação percentual e absoluta destacada"). `null` when either
  /// side is unavailable or [previousMonthValue] is `0` (never `NaN`/
  /// `Infinity`) — the presentation layer renders `null` as "sem comparação
  /// disponível", never as `0%`.
  double? get momChangePercentage => _percentChange(previousMonthValue);

  /// Same as [momChangePercentage], against [previousYearValue] instead.
  double? get yoyChangePercentage => _percentChange(previousYearValue);

  /// `value - previousMonthValue` — "variação absoluta" of the MoM
  /// comparison. `null` when either side is unavailable.
  double? get momChangeAbsolute => _absoluteChange(previousMonthValue);

  /// Same as [momChangeAbsolute], against [previousYearValue] instead.
  double? get yoyChangeAbsolute => _absoluteChange(previousYearValue);

  double? _percentChange(double? previous) {
    final current = value;
    if (current == null || previous == null || previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  double? _absoluteChange(double? previous) {
    final current = value;
    if (current == null || previous == null) return null;
    return current - previous;
  }

  @override
  bool operator ==(Object other) {
    return other is SalesDashboardKpi &&
        status == other.status &&
        value == other.value &&
        previousMonthValue == other.previousMonthValue &&
        previousYearValue == other.previousYearValue &&
        failureMessage == other.failureMessage;
  }

  @override
  int get hashCode => Object.hash(
    status,
    value,
    previousMonthValue,
    previousYearValue,
    failureMessage,
  );
}
