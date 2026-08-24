import '../../../../core/errors/errors.dart';
import '../value_objects/opportunity_status.dart';

String? normalizeOpportunityOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Builds the failure returned when a use case tries to move an Opportunity
/// through a status transition [Opportunity.canTransitionStatusTo] rejects.
Failure invalidOpportunityStatusTransitionFailure({
  required OpportunityStatus from,
  required OpportunityStatus to,
}) {
  return ValidationFailure(
    'Cannot move opportunity from $from to $to.',
    fieldErrors: const <String, String>{
      'status': 'Invalid opportunity status transition.',
    },
    code: 'invalid_opportunity_status_transition',
  );
}

/// Builds the failure returned when a use case tries to change the pipeline
/// stage of an Opportunity that is no longer open (won/lost).
Failure opportunityStageChangeBlockedFailure({
  required OpportunityStatus status,
}) {
  return ValidationFailure(
    'Cannot change the stage of a $status opportunity.',
    fieldErrors: const <String, String>{
      'stageId': 'Stage cannot change once the opportunity is closed.',
    },
    code: 'opportunity_stage_change_blocked',
  );
}
