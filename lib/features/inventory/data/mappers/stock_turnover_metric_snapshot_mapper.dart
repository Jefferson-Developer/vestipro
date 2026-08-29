import 'package:injectable/injectable.dart';

import '../../domain/entities/stock_turnover_metric_snapshot.dart';
import '../../domain/value_objects/stock_coverage_status.dart';
import '../../domain/value_objects/stock_turnover_scope_type.dart';
import '../dtos/stock_turnover_metric_snapshot_dto.dart';

@lazySingleton
final class StockTurnoverMetricSnapshotMapper {
  const StockTurnoverMetricSnapshotMapper();

  StockTurnoverMetricSnapshot toEntity(StockTurnoverMetricSnapshotDto dto) {
    return StockTurnoverMetricSnapshot(
      organizationId: dto.organizationId,
      scopeType: _parseScopeType(dto.scopeType),
      scopeId: dto.scopeId,
      periodStart: dto.periodStart,
      periodEnd: dto.periodEnd,
      coveredDays: dto.coveredDays,
      sellThroughRate: dto.sellThroughRate,
      stockCoverageDays: dto.stockCoverageDays,
      turnoverRate: dto.turnoverRate,
      openingStockQuantity: dto.openingStockQuantity,
      receivedQuantity: dto.receivedQuantity,
      soldQuantity: dto.soldQuantity,
      closingStockQuantity: dto.closingStockQuantity,
      averageStockQuantity: dto.averageStockQuantity,
      averageDailySalesQuantity: dto.averageDailySalesQuantity,
      coverageStatus: _parseCoverageStatus(dto.coverageStatus),
      generatedAt: dto.generatedAt,
    );
  }

  StockTurnoverMetricSnapshotDto toDto(StockTurnoverMetricSnapshot entity) {
    return StockTurnoverMetricSnapshotDto(
      id: '${entity.scopeType.code}_${entity.scopeId}_${entity.periodStart.toIso8601String()}_${entity.periodEnd.toIso8601String()}',
      organizationId: entity.organizationId,
      scopeType: entity.scopeType.code,
      scopeId: entity.scopeId,
      periodStart: entity.periodStart,
      periodEnd: entity.periodEnd,
      coveredDays: entity.coveredDays,
      sellThroughRate: entity.sellThroughRate,
      stockCoverageDays: entity.stockCoverageDays,
      turnoverRate: entity.turnoverRate,
      openingStockQuantity: entity.openingStockQuantity,
      receivedQuantity: entity.receivedQuantity,
      soldQuantity: entity.soldQuantity,
      closingStockQuantity: entity.closingStockQuantity,
      averageStockQuantity: entity.averageStockQuantity,
      averageDailySalesQuantity: entity.averageDailySalesQuantity,
      coverageStatus: entity.coverageStatus.code,
      generatedAt: entity.generatedAt,
    );
  }

  StockTurnoverScopeType _parseScopeType(String raw) {
    return switch (raw) {
      'product' => StockTurnoverScopeType.product,
      'variant' => StockTurnoverScopeType.variant,
      'collection' => StockTurnoverScopeType.collection,
      'warehouse' => StockTurnoverScopeType.warehouse,
      _ => throw ArgumentError.value(
        raw,
        'raw',
        'Unknown stock turnover scope type.',
      ),
    };
  }

  StockCoverageStatus _parseCoverageStatus(String raw) {
    return switch (raw) {
      'ready' => StockCoverageStatus.ready,
      'noRecentSales' => StockCoverageStatus.noRecentSales,
      'noStockBaseline' => StockCoverageStatus.noStockBaseline,
      _ => throw ArgumentError.value(
        raw,
        'raw',
        'Unknown stock coverage status.',
      ),
    };
  }
}
