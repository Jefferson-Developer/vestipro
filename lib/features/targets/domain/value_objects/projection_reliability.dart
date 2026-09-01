/// How much a [ClosingProjectionResult] should be trusted (TASK-119,
/// EPIC-15) — never itself a business decision the UI hides, always
/// surfaced as an explicit label next to the projected value.
///
/// See `docs/architecture/closing-projection-methodology.md` for the full
/// methodology this classification is part of.
enum ProjectionReliability {
  /// Fewer than 10% of the period has elapsed: too little pace data to
  /// extrapolate with confidence. The projected value is still shown (never
  /// hidden), but the UI must flag it as low-confidence.
  lowConfidence,

  /// Enough of the period has elapsed (>= 10%) for the linear extrapolation
  /// to be a reasonable estimate.
  reliable,

  /// The period has already ended: there is nothing left to project, the
  /// "projection" is simply the final realized value.
  periodEnded,
}
