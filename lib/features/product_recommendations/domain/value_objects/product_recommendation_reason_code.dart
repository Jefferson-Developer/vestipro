/// Why one specific [ProductRecommendationItem] was suggested — always
/// exposed to the UI alongside the human-readable `reasonLabel`, so a
/// recommendation is never presented without a visible justification
/// (`tasks.md`/TASK-190: "nunca uma lista sem justificativa alguma").
enum ProductRecommendationReasonCode {
  /// `ProductRecommendationScopeType.product` scope: "clientes que
  /// compraram X também compraram Y".
  boughtTogether,

  /// `ProductRecommendationScopeType.customer` scope, personalized: "você
  /// comprou X; clientes com o mesmo perfil de compra também levaram Y".
  purchaseHistorySimilarity,

  /// Company-wide best-seller — either the standalone `segment` scope, or
  /// the fallback used for a `customer` scope with insufficient personal
  /// history (always paired with `fallbackApplied: true` in that case).
  bestSeller,
}

extension ProductRecommendationReasonCodeValue
    on ProductRecommendationReasonCode {
  /// The exact string persisted in Firestore
  /// (`ProductRecommendationItem.reasonCode`) — must stay in sync with
  /// `functions/src/recommendations/recommendation-shared.ts`'s
  /// `RecommendationReasonCode` union.
  String get code {
    return switch (this) {
      ProductRecommendationReasonCode.boughtTogether => 'boughtTogether',
      ProductRecommendationReasonCode.purchaseHistorySimilarity =>
        'purchaseHistorySimilarity',
      ProductRecommendationReasonCode.bestSeller => 'bestSeller',
    };
  }
}

/// Parses [raw] (as persisted in Firestore) into a
/// [ProductRecommendationReasonCode], throwing [ArgumentError] for anything
/// unrecognized.
ProductRecommendationReasonCode parseProductRecommendationReasonCode(
  String raw,
) {
  return switch (raw) {
    'boughtTogether' => ProductRecommendationReasonCode.boughtTogether,
    'purchaseHistorySimilarity' =>
      ProductRecommendationReasonCode.purchaseHistorySimilarity,
    'bestSeller' => ProductRecommendationReasonCode.bestSeller,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown product recommendation reason code.',
    ),
  };
}
