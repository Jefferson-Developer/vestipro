import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/insight_severity.dart';
import '../value_objects/insight_status.dart';
import '../value_objects/insight_type.dart';
import 'insight_action.dart';
import 'insight_estimated_impact.dart';
import 'insight_evidence.dart';

part 'insight.freezed.dart';

@freezed
abstract class Insight with _$Insight {
  const Insight._();

  const factory Insight({
    required String id,
    required InsightType type,
    required String title,
    required String description,
    @Default(<InsightEvidence>[]) List<InsightEvidence> evidence,
    required InsightEstimatedImpact estimatedImpact,
    required InsightSeverity severity,
    required double confidenceScore,
    required String recommendation,
    required InsightAction quickAction,
    @Default(<InsightAction>[]) List<InsightAction> secondaryActions,
    required String organizationId,
    required String companyId,
    required String recipientUserId,
    String? customerId,
    String? productId,
    String? sellerId,
    required DateTime generatedAt,
    required DateTime expiresAt,
    required InsightStatus status,
  }) = _Insight;

  String get deduplicationKey {
    final relatedEntityId = customerId ?? productId ?? sellerId ?? 'global';
    return '${type.name}:$relatedEntityId';
  }
}
