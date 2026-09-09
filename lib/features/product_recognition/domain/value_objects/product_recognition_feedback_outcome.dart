/// Feedback a seller gives after reviewing `ProductRecognitionResult`'s
/// candidates (TASK-191, EPIC-28) — "era este" / "não era nenhum" — the
/// quality-tracking signal `tasks.md`/TASK-191 requires.
enum ProductRecognitionFeedbackOutcome {
  /// One of the presented candidates was the actual product.
  matched,

  /// None of the presented candidates matched (including when
  /// [ProductRecognitionResult.belowThreshold] was already `true` and no
  /// candidate was even shown).
  noneMatched;

  /// The exact wire value `submitProductRecognitionFeedback` expects —
  /// identical to [name], kept as an explicit method (not a raw `.name`
  /// call at every call site) so the wire contract is documented in one
  /// place.
  String toWireValue() => name;
}
