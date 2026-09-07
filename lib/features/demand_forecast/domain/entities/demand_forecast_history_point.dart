/// One real (chronological) monthly point of a scope's demand history, as
/// used to fit the `DemandForecast` (TASK-185, EPIC-27). [observed] is
/// `false` for a month synthesized as a zero-quantity gap (no commercial
/// aggregate existed for that month at calculation time) — surfaced to the
/// gestor so the "histórico real" chart never implies more data than
/// actually exists.
final class DemandForecastHistoryPoint {
  const DemandForecastHistoryPoint({
    required this.periodKey,
    required this.quantity,
    required this.observed,
  });

  /// `YYYY-MM`.
  final String periodKey;
  final double quantity;
  final bool observed;
}
