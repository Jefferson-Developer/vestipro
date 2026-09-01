import 'package:injectable/injectable.dart';

import '../../domain/entities/insight.dart';
import '../../domain/entities/insight_action.dart';
import '../../domain/entities/insight_estimated_impact.dart';
import '../../domain/entities/insight_evidence.dart';
import '../../domain/value_objects/insight_action_type.dart';
import '../../domain/value_objects/insight_severity.dart';
import '../../domain/value_objects/insight_status.dart';
import '../../domain/value_objects/insight_type.dart';
import '../dtos/insight_dto.dart';

@lazySingleton
final class InsightMapper {
  const InsightMapper();

  Insight toEntity(InsightDto dto) {
    return Insight(
      id: dto.id,
      type: _typeFromCode(dto.type),
      title: dto.title,
      description: dto.description,
      evidence: dto.evidence
          .map(
            (item) => InsightEvidence(
              code: item['code'] as String,
              label: item['label'] as String,
              value: item['value'] as String,
              numericValue: (item['numericValue'] as num?)?.toDouble(),
              unit: item['unit'] as String?,
            ),
          )
          .toList(growable: false),
      estimatedImpact: InsightEstimatedImpact(
        amount: (dto.estimatedImpact['amount'] as num?)?.toDouble(),
        percentage: (dto.estimatedImpact['percentage'] as num?)?.toDouble(),
        currencyCode: (dto.estimatedImpact['currencyCode'] as String?) ?? 'BRL',
      ),
      severity: _severityFromCode(dto.severity),
      confidenceScore: dto.confidenceScore,
      recommendation: dto.recommendation,
      quickAction: _actionFromJson(dto.quickAction),
      secondaryActions: dto.secondaryActions
          .map(_actionFromJson)
          .toList(growable: false),
      organizationId: dto.organizationId,
      companyId: dto.companyId,
      recipientUserId: dto.recipientUserId,
      customerId: dto.customerId,
      productId: dto.productId,
      sellerId: dto.sellerId,
      generatedAt: dto.generatedAt,
      expiresAt: dto.expiresAt,
      status: _statusFromCode(dto.status),
    );
  }

  InsightDto toDto(Insight entity) {
    return InsightDto(
      id: entity.id,
      type: entity.type.name,
      title: entity.title,
      description: entity.description,
      evidence: entity.evidence
          .map(
            (item) => <String, dynamic>{
              'code': item.code,
              'label': item.label,
              'value': item.value,
              'numericValue': item.numericValue,
              'unit': item.unit,
            },
          )
          .toList(growable: false),
      estimatedImpact: <String, dynamic>{
        'amount': entity.estimatedImpact.amount,
        'percentage': entity.estimatedImpact.percentage,
        'currencyCode': entity.estimatedImpact.currencyCode,
      },
      severity: entity.severity.name,
      confidenceScore: entity.confidenceScore,
      recommendation: entity.recommendation,
      quickAction: _actionToJson(entity.quickAction),
      secondaryActions: entity.secondaryActions
          .map(_actionToJson)
          .toList(growable: false),
      organizationId: entity.organizationId,
      companyId: entity.companyId,
      recipientUserId: entity.recipientUserId,
      customerId: entity.customerId,
      productId: entity.productId,
      sellerId: entity.sellerId,
      generatedAt: entity.generatedAt,
      expiresAt: entity.expiresAt,
      status: entity.status.name,
    );
  }

  InsightAction _actionFromJson(Map<String, dynamic> json) {
    return InsightAction(
      type: _actionTypeFromCode(json['type'] as String),
      label: json['label'] as String,
      route: json['route'] as String?,
      customerId: json['customerId'] as String?,
      productId: json['productId'] as String?,
      sellerId: json['sellerId'] as String?,
      payload: Map<String, Object?>.unmodifiable(
        (json['payload'] as Map?)?.cast<String, Object?>() ??
            const <String, Object?>{},
      ),
    );
  }

  Map<String, dynamic> _actionToJson(InsightAction action) {
    return <String, dynamic>{
      'type': action.type.name,
      'label': action.label,
      'route': action.route,
      'customerId': action.customerId,
      'productId': action.productId,
      'sellerId': action.sellerId,
      'payload': action.payload,
    };
  }

  InsightType _typeFromCode(String code) {
    return InsightType.values.firstWhere(
      (value) => value.name == code,
      orElse: () => throw ArgumentError.value(code, 'code', 'Unknown type.'),
    );
  }

  InsightStatus _statusFromCode(String code) {
    return switch (code) {
      'fresh' => InsightStatus.fresh,
      'viewed' => InsightStatus.viewed,
      'inProgress' => InsightStatus.inProgress,
      'dismissed' => InsightStatus.dismissed,
      'resolved' => InsightStatus.resolved,
      _ => throw ArgumentError.value(code, 'code', 'Unknown status.'),
    };
  }

  InsightSeverity _severityFromCode(String code) {
    return InsightSeverity.values.firstWhere(
      (value) => value.name == code,
      orElse: () =>
          throw ArgumentError.value(code, 'code', 'Unknown severity.'),
    );
  }

  InsightActionType _actionTypeFromCode(String code) {
    return InsightActionType.values.firstWhere(
      (value) => value.name == code,
      orElse: () =>
          throw ArgumentError.value(code, 'code', 'Unknown action type.'),
    );
  }
}
