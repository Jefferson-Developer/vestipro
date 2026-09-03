/// Which prior period [SalesDashboardGroupRow]s (and the "Crescimento"
/// column of the drill-down table) are compared against (TASK-135, seção
/// 12.3 de `tasks.md`: "comparação de período") — independent from the KPI
/// cards, which always show both MoM and YoY growth at once (same precedent
/// `ExecutiveDashboardSnapshot.revenueGrowthMoM`/`.revenueGrowthYoY` already
/// set), since a per-row table showing four numbers per KPI would be
/// unreadable at this density.
enum SalesDashboardComparisonMode { previousMonth, previousYear }

extension SalesDashboardComparisonModeMapping on SalesDashboardComparisonMode {
  String get code => switch (this) {
    SalesDashboardComparisonMode.previousMonth => 'mom',
    SalesDashboardComparisonMode.previousYear => 'yoy',
  };

  static SalesDashboardComparisonMode fromCode(String? code) {
    return code == 'yoy'
        ? SalesDashboardComparisonMode.previousYear
        : SalesDashboardComparisonMode.previousMonth;
  }
}
