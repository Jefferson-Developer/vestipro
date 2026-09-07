import '../value_objects/replenishment_decision_action.dart';

/// One append-only entry of a `ReplenishmentSuggestion.decisionAudit`
/// (TASK-184) — written exclusively by `decideReplenishmentSuggestion`.
/// `ReplenishmentSuggestion.decidedBy`/`decidedByName`/`decidedAt` always
/// mirror the *last* entry of this list, but the list itself is never
/// truncated: a future re-opened workflow (if one is ever added) would still
/// be able to see every decision ever made over the suggestion's lifetime.
final class ReplenishmentDecisionAuditEntry {
  const ReplenishmentDecisionAuditEntry({
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.at,
    this.note,
  });

  final ReplenishmentDecisionAction action;
  final String actorId;
  final String actorName;
  final DateTime at;
  final String? note;
}
