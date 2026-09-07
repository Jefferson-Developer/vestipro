/// Status of one `DemandForecast` (TASK-185, EPIC-27).
///
/// Written exclusively by the monthly scheduled Cloud Function
/// (`calculateDemandForecasts`) — never by a client action, and never
/// changed after the fact except by `evaluateDemandForecastAccuracy` filling
/// in `actualQuantity`/`absolutePercentageError` on an already-`forecast`
/// document's periods (the status itself never flips).
enum DemandForecastStatus {
  /// A real projection was computed — always accompanied by a non-empty
  /// `forecastPeriods` list, each with a confidence interval
  /// (`tasks.md`/TASK-185: "Toda previsão exibida inclui intervalo de
  /// confiança").
  forecast,

  /// The scope (produto/coleção/região) had fewer than the minimum required
  /// months of real commercial history — never a fabricated number
  /// (`tasks.md`/TASK-185: "Modelo nunca gera número para combinação... com
  /// histórico insuficiente"). `forecastPeriods` is always empty for this
  /// status.
  insufficientData,
}

extension DemandForecastStatusCode on DemandForecastStatus {
  /// The exact string persisted in Firestore (`DemandForecast.status`) —
  /// must stay in sync with
  /// `functions/src/demand-forecast/demand-forecast-shared.ts`'s
  /// `DemandForecastCalculationResult.status` union.
  String get code {
    return switch (this) {
      DemandForecastStatus.forecast => 'forecast',
      DemandForecastStatus.insufficientData => 'insufficientData',
    };
  }
}

/// Parses [raw] (as persisted in Firestore) into a [DemandForecastStatus],
/// throwing [ArgumentError] for anything unrecognized.
DemandForecastStatus parseDemandForecastStatus(String raw) {
  return switch (raw) {
    'forecast' => DemandForecastStatus.forecast,
    'insufficientData' => DemandForecastStatus.insufficientData,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown demand forecast status.',
    ),
  };
}

/// The reason [DemandForecastStatus.insufficientData] was returned — `null`
/// for every other status.
enum DemandForecastInsufficientDataReason { noHistory, notEnoughHistory }

extension DemandForecastInsufficientDataReasonCode
    on DemandForecastInsufficientDataReason {
  String get code {
    return switch (this) {
      DemandForecastInsufficientDataReason.noHistory => 'noHistory',
      DemandForecastInsufficientDataReason.notEnoughHistory =>
        'notEnoughHistory',
    };
  }
}

DemandForecastInsufficientDataReason parseDemandForecastInsufficientDataReason(
  String raw,
) {
  return switch (raw) {
    'noHistory' => DemandForecastInsufficientDataReason.noHistory,
    'notEnoughHistory' => DemandForecastInsufficientDataReason.notEnoughHistory,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown demand forecast insufficient data reason.',
    ),
  };
}
