sealed class SalesPipelineEvent {
  const SalesPipelineEvent();
}

final class SalesPipelineStarted extends SalesPipelineEvent {
  const SalesPipelineStarted({
    required this.organizationId,
    this.companyId,
    required this.userId,
    this.responsibleUserIds = const <String>{},
  });

  final String organizationId;
  final String? companyId;
  final String userId;

  /// Restricts the board to opportunities responsible to one of these
  /// users. Empty means no restriction (full organization/company scope) —
  /// see `OpportunityRepository.listByOrganization` docs for the RBAC
  /// scoping contract this mirrors from `LeadListFilters` (TASK-056).
  final Set<String> responsibleUserIds;
}

final class SalesPipelineRetried extends SalesPipelineEvent {
  const SalesPipelineRetried();
}

/// Requests moving [opportunityId] onto [targetStageId]. Fired by both the
/// Web drag-and-drop board and the mobile "Mover para estágio X" action —
/// the single entry point into the domain move flow, so neither platform
/// drifts into its own logic (TASK-058 business rule).
///
/// [SalesPipelineBloc] rejects this outright when [targetStageId] resolves
/// to a terminal (won/lost) stage: closing an Opportunity always requires a
/// reason, which this event does not carry — see
/// [SalesPipelineOpportunityClosedWithReason].
final class SalesPipelineOpportunityMoveRequested extends SalesPipelineEvent {
  const SalesPipelineOpportunityMoveRequested({
    required this.opportunityId,
    required this.targetStageId,
  });

  final String opportunityId;
  final String targetStageId;
}

/// Closes [opportunityId] by moving it onto the terminal [targetStageId],
/// after the caller (the page) has already collected the mandatory
/// won/lost [reasonId] — never trusted as sufficient by itself:
/// [SalesPipelineBloc] still re-validates [targetStageId] is actually a
/// terminal stage before calling `MarkOpportunityWonUseCase`/
/// `MarkOpportunityLostUseCase`.
final class SalesPipelineOpportunityClosedWithReason
    extends SalesPipelineEvent {
  const SalesPipelineOpportunityClosedWithReason({
    required this.opportunityId,
    required this.targetStageId,
    required this.reasonId,
    this.note,
  });

  final String opportunityId;
  final String targetStageId;
  final String reasonId;
  final String? note;
}

final class SalesPipelineActionDismissed extends SalesPipelineEvent {
  const SalesPipelineActionDismissed();
}
