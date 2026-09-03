/// Which column [SalesDashboardGroupRow]s are ordered by in the Sales
/// Dashboard's drill-down table (TASK-135, seção 12.3 de `tasks.md`:
/// "ordenação") — always applied client-side over the already-bounded rows
/// [LoadSalesDashboardGroupRowsUseCase] fetched, never a second query.
enum SalesDashboardSortField { revenue, orders, quantity, label }

extension SalesDashboardSortFieldMapping on SalesDashboardSortField {
  String get code => switch (this) {
    SalesDashboardSortField.revenue => 'revenue',
    SalesDashboardSortField.orders => 'orders',
    SalesDashboardSortField.quantity => 'quantity',
    SalesDashboardSortField.label => 'label',
  };

  static SalesDashboardSortField fromCode(String? code) {
    for (final field in SalesDashboardSortField.values) {
      if (field.code == code) return field;
    }
    return SalesDashboardSortField.revenue;
  }
}
