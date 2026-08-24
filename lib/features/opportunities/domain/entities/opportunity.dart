import 'package:freezed_annotation/freezed_annotation.dart';

import '../opportunity_status_transition_rules.dart';
import '../value_objects/opportunity_status.dart';
import '../value_objects/opportunity_sync_status.dart';

part 'opportunity.freezed.dart';

/// Opportunity model for EPIC-07 (CRM): the base of the sales pipeline
/// described in section 8 of `tasks.md`.
///
/// The tenant field [organizationId] is immutable after creation. Business
/// code must resolve it from the authenticated session, never from a form
/// field.
///
/// [revenueForecast] is always a derived value (`estimatedValue *
/// probability / 100`, see [calculateRevenueForecast]), never a
/// user-editable field: it is computed by `CreateOpportunityUseCase` at
/// creation and kept in sync by `RecalculateRevenueForecastUseCase`
/// whenever [estimatedValue] or [probability] changes. It is stored (rather
/// than only computed on read) so pipeline reports/dashboards can query and
/// aggregate it directly without recomputing per Opportunity.
///
/// Every Opportunity is traceable to its origin: [customerId] and/or
/// [leadId] — never both null, enforced by `CreateOpportunityUseCase`.
///
/// [status] is a coarse-grained outcome (open/won/lost) distinct from the
/// pipeline [stageId] (the configurable funnel step from TASK-058). Once
/// [status] is [OpportunityStatus.won] or [OpportunityStatus.lost] it is
/// terminal: [canTransitionStatusTo] rejects every other status, and
/// [canChangeStage] becomes `false` so the pipeline stage can no longer be
/// edited as a routine action. Reopening a closed Opportunity is
/// intentionally out of this task's scope; when introduced, it must be an
/// explicit, audited action, never a regular stage/status edit.
@freezed
abstract class Opportunity with _$Opportunity {
  const Opportunity._();

  const factory Opportunity({
    required String id,
    required String organizationId,
    String? companyId,
    required String title,
    String? description,
    String? customerId,
    String? leadId,
    required double estimatedValue,
    required int probability,
    required double revenueForecast,
    required String responsibleUserId,
    required String stageId,
    required OpportunityStatus status,
    required DateTime expectedCloseDate,
    String? wonReason,
    String? lostReason,
    DateTime? closedAt,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    required int version,
    required OpportunitySyncStatus syncStatus,
  }) = _Opportunity;

  /// Whether the domain FSM allows moving [status] to [target].
  bool canTransitionStatusTo(OpportunityStatus target) {
    return isValidOpportunityStatusTransition(status, target);
  }

  /// Whether [stageId] may currently change. Blocked once the Opportunity is
  /// closed (won/lost); a closed Opportunity never changes stage through the
  /// regular `UpdateOpportunityStageUseCase` flow.
  bool get canChangeStage => status == OpportunityStatus.open;

  /// Recomputes the revenue forecast from [estimatedValue] and
  /// [probability]. Never negative because [estimatedValue] is validated as
  /// non-negative and [probability] as `0..100` at creation/update time.
  double calculateRevenueForecast() => estimatedValue * probability / 100.0;
}
