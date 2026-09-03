/// Which column [CustomerDashboardRankingRow]s are ordered by in the
/// Customer Dashboard's ranking table (TASK-136, seção 12.3 de `tasks.md`:
/// "ordenação") — always applied client-side over the already-bounded rows
/// `LoadCustomerDashboardRankingUseCase` fetched, never a second query, same
/// precedent `SalesDashboardSortField` already sets.
enum CustomerDashboardSortField { revenue, frequency, averageTicket }

extension CustomerDashboardSortFieldMapping on CustomerDashboardSortField {
  String get code => switch (this) {
    CustomerDashboardSortField.revenue => 'revenue',
    CustomerDashboardSortField.frequency => 'frequency',
    CustomerDashboardSortField.averageTicket => 'averageTicket',
  };

  static CustomerDashboardSortField fromCode(String? code) {
    for (final field in CustomerDashboardSortField.values) {
      if (field.code == code) return field;
    }
    return CustomerDashboardSortField.revenue;
  }
}
