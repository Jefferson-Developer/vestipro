/// The dimension a `ProductRecommendation` (TASK-190, EPIC-28) is scoped to.
enum ProductRecommendationScopeType {
  /// "Clientes que compraram X também compraram Y" — anchored on a specific
  /// product (catalog grid/product detail page). Never falls back to
  /// best-sellers: a product without a real "bought together" signal simply
  /// has no document at all (see the Cloud Function's own documentation).
  product,

  /// Personalized recommendation for a specific customer, derived from the
  /// co-occurrence of every product that customer already purchased. Always
  /// has a document, even for a brand-new customer (best-sellers fallback,
  /// or an explicit "insufficient data" result — never a missing document).
  customer,

  /// Company-wide "mais vendidos" — a single document per company, usable as
  /// a generic recommendation shelf without a specific product/customer
  /// context, and as the fallback source for [customer] scope.
  segment,
}

extension ProductRecommendationScopeTypeCode on ProductRecommendationScopeType {
  /// The exact string persisted in Firestore
  /// (`ProductRecommendation.scopeType`) — must stay in sync with
  /// `functions/src/recommendations/recommendation-shared.ts`'s
  /// `ProductRecommendationScopeType` union.
  String get code {
    return switch (this) {
      ProductRecommendationScopeType.product => 'product',
      ProductRecommendationScopeType.customer => 'customer',
      ProductRecommendationScopeType.segment => 'segment',
    };
  }
}

/// Parses [raw] (as persisted in Firestore) into a
/// [ProductRecommendationScopeType], throwing [ArgumentError] for anything
/// unrecognized — same "fail loudly on a corrupted/unknown value" rule every
/// other value-object parser in this codebase follows.
ProductRecommendationScopeType parseProductRecommendationScopeType(String raw) {
  return switch (raw) {
    'product' => ProductRecommendationScopeType.product,
    'customer' => ProductRecommendationScopeType.customer,
    'segment' => ProductRecommendationScopeType.segment,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown product recommendation scope type.',
    ),
  };
}

/// Fixed `scopeId` for the company-wide "mais vendidos" fallback/segment
/// recommendation — must stay in sync with
/// `functions/src/recommendations/recommendation-shared.ts`'s
/// `SEGMENT_BEST_SELLERS_SCOPE_ID`.
const String kProductRecommendationSegmentBestSellersScopeId =
    'company-best-sellers';
