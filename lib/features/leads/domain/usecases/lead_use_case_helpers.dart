import '../../../../core/errors/errors.dart';
import '../value_objects/lead_status.dart';

String? normalizeLeadOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Builds the failure returned when a use case tries to move a Lead through
/// a transition [Lead.canTransitionTo] rejects.
Failure invalidLeadStatusTransitionFailure({
  required LeadStatus from,
  required LeadStatus to,
}) {
  return ValidationFailure(
    'Cannot move lead from $from to $to.',
    fieldErrors: const <String, String>{
      'status': 'Invalid lead status transition.',
    },
    code: 'invalid_lead_status_transition',
  );
}
