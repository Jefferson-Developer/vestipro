/// Status of one `ReplenishmentSuggestion` (TASK-184, EPIC-27).
///
/// `suggested`/`insufficientData` are the only two values the weekly
/// scheduled Cloud Function (`calculateReplenishmentSuggestions`) ever
/// writes. `accepted`/`adjusted`/`discarded` are exclusively set by a human
/// decision (`decideReplenishmentSuggestion`) and, once set, are frozen: the
/// next scheduled run never overwrites a suggestion already in one of these
/// three states for the same period (`tasks.md`/TASK-184: "Alteração de
/// parâmetros de cálculo por organização não altera retroativamente
/// cálculos já aceitos").
enum ReplenishmentSuggestionStatus {
  /// A numeric quantity was computed from the variant's recent turnover —
  /// still awaiting a human decision.
  suggested,

  /// The variant had no reliable turnover history for the calculation
  /// (brand-new product, no recent sales or no stock baseline) — never a
  /// number picked out of thin air. Still awaiting a human decision; a
  /// gestor may `adjust` with a manually chosen quantity if they have their
  /// own estimate.
  insufficientData,

  /// Accepted exactly as suggested — a `ReplenishmentDraftOrder` was
  /// created with the suggested quantity.
  accepted,

  /// Accepted with a manually chosen quantity — a `ReplenishmentDraftOrder`
  /// was created with that quantity instead of the suggested one.
  adjusted,

  /// Rejected — no `ReplenishmentDraftOrder` was created.
  discarded,
}

extension ReplenishmentSuggestionStatusCode on ReplenishmentSuggestionStatus {
  /// The exact string persisted in Firestore
  /// (`ReplenishmentSuggestion.status`) — must stay in sync with
  /// `functions/src/replenishment/replenishment-calculation-shared.ts`'s
  /// `ReplenishmentSuggestionStatus` union.
  String get code {
    return switch (this) {
      ReplenishmentSuggestionStatus.suggested => 'suggested',
      ReplenishmentSuggestionStatus.insufficientData => 'insufficientData',
      ReplenishmentSuggestionStatus.accepted => 'accepted',
      ReplenishmentSuggestionStatus.adjusted => 'adjusted',
      ReplenishmentSuggestionStatus.discarded => 'discarded',
    };
  }

  /// Whether this status was set by a human decision and is therefore
  /// frozen — the scheduled calculation never overwrites it again for the
  /// same period.
  bool get isDecided =>
      this == ReplenishmentSuggestionStatus.accepted ||
      this == ReplenishmentSuggestionStatus.adjusted ||
      this == ReplenishmentSuggestionStatus.discarded;
}

/// Parses [raw] (as persisted in Firestore) into a
/// [ReplenishmentSuggestionStatus], throwing [ArgumentError] for anything
/// unrecognized — the same "fail loudly on a corrupted/unknown value" rule
/// every other value-object parser in this codebase follows (e.g.
/// `StockAlertMapper._parseLevel`).
ReplenishmentSuggestionStatus parseReplenishmentSuggestionStatus(String raw) {
  return switch (raw) {
    'suggested' => ReplenishmentSuggestionStatus.suggested,
    'insufficientData' => ReplenishmentSuggestionStatus.insufficientData,
    'accepted' => ReplenishmentSuggestionStatus.accepted,
    'adjusted' => ReplenishmentSuggestionStatus.adjusted,
    'discarded' => ReplenishmentSuggestionStatus.discarded,
    _ => throw ArgumentError.value(
      raw,
      'raw',
      'Unknown replenishment suggestion status.',
    ),
  };
}
