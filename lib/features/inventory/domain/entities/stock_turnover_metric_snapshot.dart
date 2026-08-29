import '../value_objects/stock_coverage_status.dart';
import '../value_objects/stock_turnover_scope_type.dart';

final class StockTurnoverMetricSnapshot {
  const StockTurnoverMetricSnapshot({
    required this.organizationId,
    required this.scopeType,
    required this.scopeId,
    required this.periodStart,
    required this.periodEnd,
    required this.coveredDays,
    required this.sellThroughRate,
    required this.stockCoverageDays,
    required this.turnoverRate,
    required this.openingStockQuantity,
    required this.receivedQuantity,
    required this.soldQuantity,
    required this.closingStockQuantity,
    required this.averageStockQuantity,
    required this.averageDailySalesQuantity,
    required this.coverageStatus,
    required this.generatedAt,
  });

  final String organizationId;
  final StockTurnoverScopeType scopeType;
  final String scopeId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int coveredDays;
  final double sellThroughRate;
  final double stockCoverageDays;
  final double turnoverRate;
  final int openingStockQuantity;
  final int receivedQuantity;
  final int soldQuantity;
  final int closingStockQuantity;
  final double averageStockQuantity;
  final double averageDailySalesQuantity;
  final StockCoverageStatus coverageStatus;
  final DateTime generatedAt;
}
