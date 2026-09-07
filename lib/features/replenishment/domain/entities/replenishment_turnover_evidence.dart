import '../../../inventory/domain/value_objects/stock_coverage_status.dart';

/// The turnover/coverage evidence a `ReplenishmentSuggestion` was computed
/// from — always shown alongside the suggested quantity in the UI
/// (`tasks.md`/TASK-184: "Toda sugestão expõe a evidência do cálculo ...
/// nunca um número sem explicação"). `null` on the owning
/// `ReplenishmentSuggestion` when [ReplenishmentSuggestionStatus.insufficientData]
/// was caused by a total absence of `stockTurnoverDailyFacts` (brand-new
/// variant, never sold) — every other case still carries this evidence,
/// even when [coverageStatus] itself is not `ready`.
final class ReplenishmentTurnoverEvidence {
  const ReplenishmentTurnoverEvidence({
    required this.averageDailySalesQuantity,
    required this.stockCoverageDays,
    required this.turnoverRate,
    required this.coverageStatus,
  });

  final double averageDailySalesQuantity;
  final double stockCoverageDays;
  final double turnoverRate;
  final StockCoverageStatus coverageStatus;
}
