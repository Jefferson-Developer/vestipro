import '../../domain/value_objects/opportunity_outcome_type.dart';

sealed class OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminEvent();
}

final class OpportunityOutcomeReasonAdminStarted
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminStarted({
    required this.organizationId,
    required this.userId,
  });

  final String organizationId;
  final String userId;
}

final class OpportunityOutcomeReasonAdminRetried
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminRetried();
}

final class OpportunityOutcomeReasonAdminReasonCreated
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminReasonCreated({
    required this.type,
    required this.description,
  });

  final OpportunityOutcomeType type;
  final String description;
}

final class OpportunityOutcomeReasonAdminReasonRenamed
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminReasonRenamed({
    required this.reasonId,
    required this.description,
  });

  final String reasonId;
  final String description;
}

final class OpportunityOutcomeReasonAdminReasonDeactivated
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminReasonDeactivated(this.reasonId);

  final String reasonId;
}

final class OpportunityOutcomeReasonAdminActionDismissed
    extends OpportunityOutcomeReasonAdminEvent {
  const OpportunityOutcomeReasonAdminActionDismissed();
}
