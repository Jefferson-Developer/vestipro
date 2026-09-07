import '../value_objects/replenishment_suggestion_status.dart';

/// Result of successfully deciding a `ReplenishmentSuggestion` through
/// `decideReplenishmentSuggestion` (TASK-184) — every field here is exactly
/// what the Cloud Function returned, never recomputed client-side.
final class ReplenishmentDecisionResult {
  const ReplenishmentDecisionResult({
    required this.suggestionId,
    required this.status,
    required this.finalQuantity,
    this.draftOrderId,
  });

  final String suggestionId;

  /// Always [ReplenishmentSuggestionStatus.accepted],
  /// [ReplenishmentSuggestionStatus.adjusted] or
  /// [ReplenishmentSuggestionStatus.discarded] — never `suggested`/
  /// `insufficientData`, mirrored from [ReplenishmentDecisionAction]'s own
  /// closed set.
  final ReplenishmentSuggestionStatus status;
  final int? finalQuantity;

  /// Set only for `accept`/`adjust` — always `null` for `discard`.
  final String? draftOrderId;
}
