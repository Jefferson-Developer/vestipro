/// The three ways a gestor can decide one `ReplenishmentSuggestion`
/// (TASK-184, EPIC-27) — mirrors `ReplenishmentDecisionAction` in
/// `functions/src/replenishment/decide-replenishment-suggestion.ts`.
enum ReplenishmentDecisionAction {
  /// Accept exactly the suggested quantity.
  accept,

  /// Accept a manually chosen quantity instead of the suggested one — also
  /// a form of acceptance (a `ReplenishmentDraftOrder` is still created),
  /// just with a different final quantity.
  adjust,

  /// Reject the suggestion — no `ReplenishmentDraftOrder` is created.
  discard,
}

extension ReplenishmentDecisionActionCode on ReplenishmentDecisionAction {
  /// The exact string the `decideReplenishmentSuggestion` callable expects.
  String get code {
    return switch (this) {
      ReplenishmentDecisionAction.accept => 'accept',
      ReplenishmentDecisionAction.adjust => 'adjust',
      ReplenishmentDecisionAction.discard => 'discard',
    };
  }
}
