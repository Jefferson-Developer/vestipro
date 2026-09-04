/// Which column [ProductDashboardRankingRow]s are ordered by in the Product
/// Dashboard's ranking table (TASK-137, seção 12.3 de `tasks.md`:
/// "ordenação") — always applied by `LoadProductDashboardRankingUseCase`
/// over the already-bounded, already-fetched `productMonthly` rows, never a
/// second query, same precedent `CustomerDashboardSortField`/
/// `SalesDashboardSortField` already set.
enum ProductDashboardSortField { quantitySold, revenue, mix, discount }

extension ProductDashboardSortFieldMapping on ProductDashboardSortField {
  String get code => switch (this) {
    ProductDashboardSortField.quantitySold => 'quantity',
    ProductDashboardSortField.revenue => 'revenue',
    ProductDashboardSortField.mix => 'mix',
    ProductDashboardSortField.discount => 'discount',
  };

  static ProductDashboardSortField fromCode(String? code) {
    for (final field in ProductDashboardSortField.values) {
      if (field.code == code) return field;
    }
    return ProductDashboardSortField.quantitySold;
  }
}
