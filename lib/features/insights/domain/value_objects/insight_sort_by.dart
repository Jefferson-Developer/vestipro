/// How the Central de Oportunidades (TASK-132) orders the `Insight`s
/// currently loaded in `OpportunityCenterState.insights`.
///
/// [estimatedImpact] is always the screen's default — "A ordenação padrão
/// da tela é sempre por impacto estimado, nunca alfabética ou apenas por
/// data" — the other two values only apply once the user explicitly
/// reorders.
enum InsightSortBy {
  /// Highest `Insight.estimatedImpact` first (amount, falling back to
  /// percentage when amount is absent). The screen's mandatory default.
  estimatedImpact,

  /// Most recently generated first (`Insight.generatedAt` descending).
  generatedAt,

  /// Grouped by the related customer/seller/product id
  /// (`customerId`/`sellerId`/`productId`, falling back to `type`), then by
  /// [estimatedImpact] within each group.
  relatedEntity,
}
