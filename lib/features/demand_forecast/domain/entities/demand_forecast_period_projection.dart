/// One projected future month of a `DemandForecast` (TASK-185, EPIC-27) —
/// always carries its own confidence interval
/// ([lowerBound]/[upperBound]), never just a bare [predictedQuantity]
/// (`tasks.md`/TASK-185: "Previsão nunca é apresentada sem o intervalo de
/// confiança correspondente").
///
/// [actualQuantity]/[absolutePercentageError] start `null` and are filled in
/// later, once [periodKey] has actually happened, by the monthly
/// `evaluateDemandForecastAccuracy` Cloud Function — never by the client.
final class DemandForecastPeriodProjection {
  const DemandForecastPeriodProjection({
    required this.periodKey,
    required this.predictedQuantity,
    required this.lowerBound,
    required this.upperBound,
    this.actualQuantity,
    this.absolutePercentageError,
  });

  /// `YYYY-MM`.
  final String periodKey;
  final double predictedQuantity;
  final double lowerBound;
  final double upperBound;

  /// The real, now-known quantity for [periodKey] — `null` until
  /// `evaluateDemandForecastAccuracy` fills it in (i.e. until the projected
  /// month has actually happened and its aggregates have settled).
  final double? actualQuantity;

  /// MAPE of this single period against [actualQuantity] — `null` while
  /// [actualQuantity] itself is `null`.
  final double? absolutePercentageError;

  bool get isEvaluated => actualQuantity != null;
}
