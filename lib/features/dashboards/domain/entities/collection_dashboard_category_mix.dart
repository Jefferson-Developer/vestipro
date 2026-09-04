/// One category's share of a single [CollectionDashboardEntry]'s total
/// `revenueNet` (TASK-138, seção 12.1/12.2 de `tasks.md`: "mix médio de
/// categorias dentro da coleção") — the "mix médio" KPI this task's own
/// escopo técnico names, read as "quanto cada categoria representa do
/// faturamento da coleção", the same reading `ProductDashboardRankingRow
/// .mixPercentage` already sets for a single product's share of the
/// company's total.
///
/// Built exclusively by `LoadCollectionDashboardEntriesUseCase` from the
/// already-fetched `productMonthly` rows (TASK-133) of the owning
/// [CollectionDashboardEntry] — never a second read, never a client-side
/// scan of raw orders/products.
final class CollectionDashboardCategoryMix {
  const CollectionDashboardCategoryMix({
    required this.categoryId,
    required this.categoryName,
    required this.revenueNet,
    required this.percentage,
  });

  /// `null` for the (rare) `productMonthly` row whose product carries no
  /// `categoryId` — grouped together under [categoryName] `'Sem categoria'`,
  /// never silently dropped from the mix.
  final String? categoryId;
  final String categoryName;

  final double revenueNet;

  /// This category's [revenueNet] share of the owning
  /// [CollectionDashboardEntry]'s total `revenueNet`, `0`–`100`. `0` when the
  /// coleção's total `revenueNet` is `0` (never a `NaN`/`Infinity` division
  /// by zero).
  final double percentage;

  @override
  bool operator ==(Object other) {
    return other is CollectionDashboardCategoryMix &&
        categoryId == other.categoryId &&
        categoryName == other.categoryName &&
        revenueNet == other.revenueNet &&
        percentage == other.percentage;
  }

  @override
  int get hashCode =>
      Object.hash(categoryId, categoryName, revenueNet, percentage);
}
