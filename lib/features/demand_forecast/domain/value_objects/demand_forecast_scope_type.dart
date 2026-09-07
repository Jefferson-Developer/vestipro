/// The dimension a `DemandForecast` (TASK-185, EPIC-27) is scoped to —
/// produto, coleção ou região, exatamente como pedido pelo escopo técnico da
/// task ("previsão de demanda por produto/coleção/região").
enum DemandForecastScopeType { product, collection, region }

extension DemandForecastScopeTypeCode on DemandForecastScopeType {
  /// The exact string persisted in Firestore (`DemandForecast.scopeType`) —
  /// must stay in sync with
  /// `functions/src/demand-forecast/calculate-demand-forecasts.ts`'s
  /// `DemandForecastScopeType` union.
  String get code {
    return switch (this) {
      DemandForecastScopeType.product => 'product',
      DemandForecastScopeType.collection => 'collection',
      DemandForecastScopeType.region => 'region',
    };
  }
}

/// Parses [raw] (as persisted in Firestore) into a
/// [DemandForecastScopeType], throwing [ArgumentError] for anything
/// unrecognized — same "fail loudly on a corrupted/unknown value" rule every
/// other value-object parser in this codebase follows (e.g.
/// `parseReplenishmentSuggestionStatus`).
DemandForecastScopeType parseDemandForecastScopeType(String raw) {
  return switch (raw) {
    'product' => DemandForecastScopeType.product,
    'collection' => DemandForecastScopeType.collection,
    'region' => DemandForecastScopeType.region,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown demand forecast scope type.',
    ),
  };
}
