import '../../domain/value_objects/replenishment_decision_action.dart';
import '../../domain/value_objects/replenishment_suggestion_status.dart';

sealed class ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsEvent();
}

final class ReplenishmentSuggestionsStarted
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsStarted({
    required this.organizationId,
    required this.userId,
    this.initialWarehouseId,
  });

  final String organizationId;
  final String userId;

  /// Pre-fills the `warehouseId` filter when the screen is opened via an
  /// `Insight`'s `notifyReplenishment` quick action deep link
  /// (`/inventory/replenishment?productId=...`, TASK-128) — `null` for a
  /// plain navigation from the inventory menu.
  final String? initialWarehouseId;
}

final class ReplenishmentSuggestionsRefreshRequested
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsRefreshRequested();
}

final class ReplenishmentSuggestionsNextPageRequested
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsNextPageRequested();
}

final class ReplenishmentSuggestionsFiltersApplied
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsFiltersApplied({
    this.status,
    this.warehouseId = '',
  });

  final ReplenishmentSuggestionStatus? status;
  final String warehouseId;
}

final class ReplenishmentSuggestionsFiltersCleared
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsFiltersCleared();
}

/// Accepts/adjusts/discards one suggestion — [adjustedQuantity] is required
/// (and validated) only for [ReplenishmentDecisionAction.adjust], mirroring
/// `DecideReplenishmentSuggestionUseCase`'s own validation.
final class ReplenishmentSuggestionsDecided
    extends ReplenishmentSuggestionsEvent {
  const ReplenishmentSuggestionsDecided({
    required this.suggestionId,
    required this.action,
    this.adjustedQuantity,
    this.note,
  });

  final String suggestionId;
  final ReplenishmentDecisionAction action;
  final int? adjustedQuantity;
  final String? note;
}
