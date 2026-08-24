import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/opportunity_outcome_type.dart';

part 'opportunity_outcome_reason.freezed.dart';

/// Configurable catalog entry explaining why an Opportunity was won or lost.
///
/// Reasons are scoped by [organizationId] and are never deleted from the
/// domain model: [isActive] only controls whether a reason can be selected for
/// new closes. Closed opportunities keep a text snapshot of the reason so
/// historical records remain readable if the catalog entry is later edited or
/// deactivated.
@freezed
abstract class OpportunityOutcomeReason with _$OpportunityOutcomeReason {
  const OpportunityOutcomeReason._();

  const factory OpportunityOutcomeReason({
    required String id,
    required String organizationId,
    required OpportunityOutcomeType type,
    required String description,
    required bool isActive,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    required int version,
  }) = _OpportunityOutcomeReason;
}
