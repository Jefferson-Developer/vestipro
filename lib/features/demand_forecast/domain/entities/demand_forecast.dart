import '../value_objects/demand_forecast_scope_type.dart';
import '../value_objects/demand_forecast_status.dart';
import 'demand_forecast_history_point.dart';
import 'demand_forecast_period_projection.dart';

/// A server-computed demand projection for one produto/coleção/região
/// (TASK-185, EPIC-27), evolving TASK-184's replenishment base into a
/// forward-looking projection — always presented with its confidence
/// interval, its generation date/model version, and never a fabricated
/// number for a scope with insufficient history
/// (`tasks.md`/TASK-185's own "Regras de negócio e restrições").
///
/// One document per scope/anchor-month combination
/// (`organizations/{organizationId}/demandForecasts/
/// {companyId}_{scopeType}_{scopeId}_{anchorMonthKey}`), written exclusively
/// by the monthly scheduled `calculateDemandForecasts` Cloud Function
/// (everything except [forecastPeriods]' `actualQuantity`/
/// `absolutePercentageError`, later filled in by
/// `evaluateDemandForecastAccuracy`) — the client never writes this
/// collection directly (`firestore.rules`).
final class DemandForecast {
  const DemandForecast({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.scopeType,
    required this.scopeId,
    required this.scopeLabel,
    required this.anchorMonthKey,
    required this.status,
    required this.observedPeriodsCount,
    required this.history,
    required this.forecastPeriods,
    required this.generatedAt,
    required this.updatedAt,
    required this.version,
    this.insufficientDataReason,
    this.model,
    this.modelVersion,
    this.residualStdDev,
  });

  final String id;
  final String organizationId;
  final String companyId;
  final DemandForecastScopeType scopeType;
  final String scopeId;

  /// Display label for [scopeId] (product/collection name, or the region
  /// code itself for `region` scope) — denormalized at calculation time so
  /// the UI never has to re-fetch the referenced entity just to render a
  /// title.
  final String scopeLabel;

  /// `YYYY-MM` — the last fully-completed month the forecast was generated
  /// from; [forecastPeriods] always starts the month right after this one.
  final String anchorMonthKey;

  final DemandForecastStatus status;

  /// Reason [status] is [DemandForecastStatus.insufficientData] — `null`
  /// for [DemandForecastStatus.forecast].
  final DemandForecastInsufficientDataReason? insufficientDataReason;

  /// How many of the lookback window's months actually had real recorded
  /// activity for this scope (never counts a zero-padded gap month) — the
  /// concrete number behind the sufficiency gate
  /// (`tasks.md`/TASK-185: "histórico insuficiente").
  final int observedPeriodsCount;

  /// Identifies the statistical method used — `null` for
  /// [DemandForecastStatus.insufficientData] (nothing was fit).
  final String? model;

  /// Identifies the exact model version/tuning used — always present for
  /// [DemandForecastStatus.forecast], letting a gestor audit why a number
  /// was generated on a given date (`tasks.md`/TASK-185).
  final String? modelVersion;

  /// Standard deviation of the model's one-step-ahead residuals during
  /// fitting — the raw input the confidence interval was derived from.
  final double? residualStdDev;

  /// The real (zero-padded for gap months), chronological demand history
  /// the forecast was fit from.
  final List<DemandForecastHistoryPoint> history;

  /// Always empty for [DemandForecastStatus.insufficientData]; always
  /// non-empty (and always confidence-interval-bearing) for
  /// [DemandForecastStatus.forecast].
  final List<DemandForecastPeriodProjection> forecastPeriods;

  final DateTime generatedAt;
  final DateTime updatedAt;
  final int version;

  bool get isAvailable => status == DemandForecastStatus.forecast;
}
