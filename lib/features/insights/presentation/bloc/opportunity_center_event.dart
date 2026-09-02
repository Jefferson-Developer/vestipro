import '../../domain/entities/insight_action.dart';
import '../../domain/entities/opportunity_center_filters.dart';

sealed class OpportunityCenterEvent {
  const OpportunityCenterEvent();
}

final class OpportunityCenterStarted extends OpportunityCenterEvent {
  const OpportunityCenterStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    this.filters = OpportunityCenterFilters.empty,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final OpportunityCenterFilters filters;
}

final class OpportunityCenterFiltersChanged extends OpportunityCenterEvent {
  const OpportunityCenterFiltersChanged(this.filters);

  final OpportunityCenterFilters filters;
}

final class OpportunityCenterNextPageRequested extends OpportunityCenterEvent {
  const OpportunityCenterNextPageRequested();
}

final class OpportunityCenterRetried extends OpportunityCenterEvent {
  const OpportunityCenterRetried();
}

/// Logs `insight_opened` (TASK-132) — fired when the caller expands an
/// insight's evidence to the full detail.
final class OpportunityCenterInsightOpened extends OpportunityCenterEvent {
  const OpportunityCenterInsightOpened(this.insightId);

  final String insightId;
}

/// Logs `insight_action_clicked` (TASK-132) — fired right before the page
/// executes [action]'s already-validated navigation/flow from the origin
/// task; this bloc never re-implements that navigation itself.
final class OpportunityCenterActionExecuted extends OpportunityCenterEvent {
  const OpportunityCenterActionExecuted({
    required this.insightId,
    required this.action,
  });

  final String insightId;
  final InsightAction action;
}

final class OpportunityCenterInsightDismissed extends OpportunityCenterEvent {
  const OpportunityCenterInsightDismissed(this.insightId);

  final String insightId;
}

final class OpportunityCenterInsightResolved extends OpportunityCenterEvent {
  const OpportunityCenterInsightResolved(this.insightId);

  final String insightId;
}

/// Reverts the most recent dismiss/resolve back to the insight's previous
/// status, requested from the undo action of the `AppSnackbar` TASK-132
/// mandates.
final class OpportunityCenterUndoRequested extends OpportunityCenterEvent {
  const OpportunityCenterUndoRequested(this.insightId);

  final String insightId;
}
