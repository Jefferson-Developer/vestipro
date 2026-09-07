import 'package:injectable/injectable.dart';

import '../../../inventory/domain/value_objects/stock_coverage_status.dart';
import '../../domain/entities/replenishment_decision_audit_entry.dart';
import '../../domain/entities/replenishment_suggestion.dart';
import '../../domain/entities/replenishment_turnover_evidence.dart';
import '../../domain/value_objects/replenishment_decision_action.dart';
import '../../domain/value_objects/replenishment_suggestion_status.dart';
import '../dtos/replenishment_suggestion_dto.dart';

@lazySingleton
final class ReplenishmentSuggestionMapper {
  const ReplenishmentSuggestionMapper();

  ReplenishmentSuggestion toEntity(ReplenishmentSuggestionDto dto) {
    return ReplenishmentSuggestion(
      id: dto.id,
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      warehouseId: dto.warehouseId,
      variantId: dto.variantId,
      productId: dto.productId,
      periodStart: dto.periodStart,
      periodEnd: dto.periodEnd,
      status: parseReplenishmentSuggestionStatus(dto.status),
      insufficientDataReason: dto.insufficientDataReason,
      suggestedQuantity: dto.suggestedQuantity,
      targetStockQuantity: dto.targetStockQuantity,
      finalQuantity: dto.finalQuantity,
      currentSellableQuantity: dto.currentSellableQuantity,
      futureStockQuantity: dto.futureStockQuantity,
      turnoverEvidence: dto.turnoverEvidence == null
          ? null
          : ReplenishmentTurnoverEvidence(
              averageDailySalesQuantity:
                  dto.turnoverEvidence!.averageDailySalesQuantity,
              stockCoverageDays: dto.turnoverEvidence!.stockCoverageDays,
              turnoverRate: dto.turnoverEvidence!.turnoverRate,
              coverageStatus: _parseCoverageStatus(
                dto.turnoverEvidence!.coverageStatus,
              ),
            ),
      coverageTargetDays: dto.coverageTargetDays,
      safetyStockQuantity: dto.safetyStockQuantity,
      seasonalityFactor: dto.seasonalityFactor,
      decidedBy: dto.decidedBy,
      decidedByName: dto.decidedByName,
      decidedAt: dto.decidedAt,
      decisionAudit: dto.decisionAudit
          .map(
            (entry) => ReplenishmentDecisionAuditEntry(
              action: _parseDecisionAction(entry.action),
              actorId: entry.actorId,
              actorName: entry.actorName,
              at: entry.at,
              note: entry.note,
            ),
          )
          .toList(growable: false),
      generatedAt: dto.generatedAt,
      updatedAt: dto.updatedAt,
      version: dto.version,
    );
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

  ReplenishmentDecisionAction _parseDecisionAction(String raw) {
    return switch (raw) {
      'accept' => ReplenishmentDecisionAction.accept,
      'adjust' => ReplenishmentDecisionAction.adjust,
      'discard' => ReplenishmentDecisionAction.discard,
      _ => throw ArgumentError.value(
        raw,
        'raw',
        'Unknown replenishment decision action.',
      ),
    };
  }
}
