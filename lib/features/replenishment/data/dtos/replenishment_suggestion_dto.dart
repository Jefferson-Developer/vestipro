import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';

final class ReplenishmentTurnoverEvidenceDto {
  const ReplenishmentTurnoverEvidenceDto({
    required this.averageDailySalesQuantity,
    required this.stockCoverageDays,
    required this.turnoverRate,
    required this.coverageStatus,
  });

  factory ReplenishmentTurnoverEvidenceDto.fromJson(Map<String, dynamic> json) {
    final averageDailySalesQuantity = json['averageDailySalesQuantity'];
    final stockCoverageDays = json['stockCoverageDays'];
    final turnoverRate = json['turnoverRate'];
    final coverageStatus = json['coverageStatus'];
    if (averageDailySalesQuantity is! num ||
        stockCoverageDays is! num ||
        turnoverRate is! num ||
        coverageStatus is! String) {
      throw const ValidationException(
        'Invalid replenishment turnover evidence payload.',
        code: 'invalid_replenishment_turnover_evidence_payload',
      );
    }
    return ReplenishmentTurnoverEvidenceDto(
      averageDailySalesQuantity: averageDailySalesQuantity.toDouble(),
      stockCoverageDays: stockCoverageDays.toDouble(),
      turnoverRate: turnoverRate.toDouble(),
      coverageStatus: coverageStatus,
    );
  }

  final double averageDailySalesQuantity;
  final double stockCoverageDays;
  final double turnoverRate;
  final String coverageStatus;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'averageDailySalesQuantity': averageDailySalesQuantity,
      'stockCoverageDays': stockCoverageDays,
      'turnoverRate': turnoverRate,
      'coverageStatus': coverageStatus,
    };
  }
}

final class ReplenishmentDecisionAuditEntryDto {
  const ReplenishmentDecisionAuditEntryDto({
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.note,
  });

  factory ReplenishmentDecisionAuditEntryDto.fromJson(
    Map<String, dynamic> json,
  ) {
    final action = json['action'];
    final actorId = json['actorId'];
    final actorName = json['actorName'];
    final at = json['at'];
    final note = json['note'];
    if (action is! String ||
        actorId is! String ||
        actorName is! String ||
        at is! Timestamp ||
        (note != null && note is! String)) {
      throw const ValidationException(
        'Invalid replenishment decision audit entry payload.',
        code: 'invalid_replenishment_decision_audit_entry_payload',
      );
    }
    return ReplenishmentDecisionAuditEntryDto(
      action: action,
      actorId: actorId,
      actorName: actorName,
      at: at.toDate(),
      note: note as String?,
    );
  }

  final String action;
  final String actorId;
  final String actorName;
  final DateTime at;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'action': action,
      'actorId': actorId,
      'actorName': actorName,
      'at': Timestamp.fromDate(at),
      'note': note,
    };
  }
}

final class ReplenishmentSuggestionDto {
  const ReplenishmentSuggestionDto({
    required this.id,
    required this.organizationId,
    required this.companyId,
    required this.warehouseId,
    required this.variantId,
    required this.productId,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
    required this.suggestedQuantity,
    required this.targetStockQuantity,
    required this.currentSellableQuantity,
    required this.futureStockQuantity,
    required this.coverageTargetDays,
    required this.safetyStockQuantity,
    required this.seasonalityFactor,
    required this.decisionAudit,
    required this.generatedAt,
    required this.updatedAt,
    required this.version,
    this.insufficientDataReason,
    this.finalQuantity,
    this.turnoverEvidence,
    this.decidedBy,
    this.decidedByName,
    this.decidedAt,
  });

  factory ReplenishmentSuggestionDto.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final organizationId = json['organizationId'];
    final companyId = json['companyId'];
    final warehouseId = json['warehouseId'];
    final variantId = json['variantId'];
    final productId = json['productId'];
    final periodStart = json['periodStart'];
    final periodEnd = json['periodEnd'];
    final status = json['status'];
    final insufficientDataReason = json['insufficientDataReason'];
    final suggestedQuantity = json['suggestedQuantity'];
    final targetStockQuantity = json['targetStockQuantity'];
    final finalQuantity = json['finalQuantity'];
    final currentSellableQuantity = json['currentSellableQuantity'];
    final futureStockQuantity = json['futureStockQuantity'];
    final turnoverEvidence = json['turnoverEvidence'];
    final parametersSnapshot = json['parametersSnapshot'];
    final decidedBy = json['decidedBy'];
    final decidedByName = json['decidedByName'];
    final decidedAt = json['decidedAt'];
    final decisionAudit = json['decisionAudit'];
    final generatedAt = json['generatedAt'];
    final updatedAt = json['updatedAt'];
    final version = json['version'];

    if (organizationId is! String ||
        companyId is! String ||
        warehouseId is! String ||
        variantId is! String ||
        productId is! String ||
        periodStart is! String ||
        periodEnd is! String ||
        status is! String ||
        (insufficientDataReason != null && insufficientDataReason is! String) ||
        suggestedQuantity is! int ||
        targetStockQuantity is! int ||
        (finalQuantity != null && finalQuantity is! int) ||
        currentSellableQuantity is! int ||
        futureStockQuantity is! int ||
        (turnoverEvidence != null && turnoverEvidence is! Map) ||
        parametersSnapshot is! Map ||
        (decidedBy != null && decidedBy is! String) ||
        (decidedByName != null && decidedByName is! String) ||
        (decidedAt != null && decidedAt is! Timestamp) ||
        decisionAudit is! List ||
        generatedAt is! Timestamp ||
        updatedAt is! Timestamp ||
        version is! int) {
      throw const ValidationException(
        'Invalid replenishment suggestion payload.',
        code: 'invalid_replenishment_suggestion_payload',
      );
    }

    final parameters = Map<String, dynamic>.from(parametersSnapshot);
    final coverageTargetDays = parameters['coverageTargetDays'];
    final safetyStockQuantity = parameters['safetyStockQuantity'];
    final seasonalityFactor = parameters['seasonalityFactor'];
    if (coverageTargetDays is! num ||
        safetyStockQuantity is! num ||
        seasonalityFactor is! num) {
      throw const ValidationException(
        'Invalid replenishment suggestion parametersSnapshot payload.',
        code: 'invalid_replenishment_parameters_snapshot_payload',
      );
    }

    return ReplenishmentSuggestionDto(
      id: id,
      organizationId: organizationId,
      companyId: companyId,
      warehouseId: warehouseId,
      variantId: variantId,
      productId: productId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: status,
      insufficientDataReason: insufficientDataReason as String?,
      suggestedQuantity: suggestedQuantity,
      targetStockQuantity: targetStockQuantity,
      finalQuantity: finalQuantity as int?,
      currentSellableQuantity: currentSellableQuantity,
      futureStockQuantity: futureStockQuantity,
      turnoverEvidence: turnoverEvidence == null
          ? null
          : ReplenishmentTurnoverEvidenceDto.fromJson(
              Map<String, dynamic>.from(turnoverEvidence as Map),
            ),
      coverageTargetDays: coverageTargetDays.toDouble(),
      safetyStockQuantity: safetyStockQuantity.toDouble(),
      seasonalityFactor: seasonalityFactor.toDouble(),
      decidedBy: decidedBy as String?,
      decidedByName: decidedByName as String?,
      decidedAt: (decidedAt as Timestamp?)?.toDate(),
      decisionAudit: decisionAudit
          .map(
            (entry) => ReplenishmentDecisionAuditEntryDto.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      generatedAt: generatedAt.toDate(),
      updatedAt: updatedAt.toDate(),
      version: version,
    );
  }

  final String id;
  final String organizationId;
  final String companyId;
  final String warehouseId;
  final String variantId;
  final String productId;
  final String periodStart;
  final String periodEnd;
  final String status;
  final String? insufficientDataReason;
  final int suggestedQuantity;
  final int targetStockQuantity;
  final int? finalQuantity;
  final int currentSellableQuantity;
  final int futureStockQuantity;
  final ReplenishmentTurnoverEvidenceDto? turnoverEvidence;
  final double coverageTargetDays;
  final double safetyStockQuantity;
  final double seasonalityFactor;
  final String? decidedBy;
  final String? decidedByName;
  final DateTime? decidedAt;
  final List<ReplenishmentDecisionAuditEntryDto> decisionAudit;
  final DateTime generatedAt;
  final DateTime updatedAt;
  final int version;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'companyId': companyId,
      'warehouseId': warehouseId,
      'variantId': variantId,
      'productId': productId,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'status': status,
      'insufficientDataReason': insufficientDataReason,
      'suggestedQuantity': suggestedQuantity,
      'targetStockQuantity': targetStockQuantity,
      'finalQuantity': finalQuantity,
      'currentSellableQuantity': currentSellableQuantity,
      'futureStockQuantity': futureStockQuantity,
      'turnoverEvidence': turnoverEvidence?.toJson(),
      'parametersSnapshot': <String, dynamic>{
        'coverageTargetDays': coverageTargetDays,
        'safetyStockQuantity': safetyStockQuantity,
        'seasonalityFactor': seasonalityFactor,
      },
      'decidedBy': decidedBy,
      'decidedByName': decidedByName,
      'decidedAt': decidedAt == null ? null : Timestamp.fromDate(decidedAt!),
      'decisionAudit': decisionAudit.map((entry) => entry.toJson()).toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'version': version,
    };
  }
}
