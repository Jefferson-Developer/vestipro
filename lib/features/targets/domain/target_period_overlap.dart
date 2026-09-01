/// Whether the half-open period `[aStart, aEnd)` overlaps `[bStart, bEnd)`.
///
/// Half-open (end exclusive) so two back-to-back periods — e.g. a January
/// target ending `2026-02-01T00:00:00` and a February target starting at that
/// exact instant — never count as overlapping just for touching at the
/// boundary. Callers (`Target.overlapsWith`, `CreateTargetUseCase`) are
/// expected to have already validated `aStart < aEnd` and `bStart < bEnd`
/// individually; this function does not re-validate that.
bool targetPeriodsOverlap({
  required DateTime aStart,
  required DateTime aEnd,
  required DateTime bStart,
  required DateTime bEnd,
}) {
  return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
}
