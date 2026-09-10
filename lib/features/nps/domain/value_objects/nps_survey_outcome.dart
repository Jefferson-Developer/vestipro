/// The state an NPS survey link (TASK-202, EPIC-30) resolves into for the
/// anonymous customer opening it — mirrors `NpsSurveyOutcome` in
/// `functions/src/nps/nps-shared.ts`, kept in sync manually (same trade-off
/// already accepted for other client/Functions enum pairs in this codebase,
/// e.g. `CatalogShareOutcome`).
enum NpsSurveyOutcome {
  /// Not yet answered and not yet expired — the response form is safe to
  /// show.
  pending,

  /// Already answered once — a survey is answered exactly once, a
  /// resubmission of the same link is never accepted again.
  answered,

  /// Past its `expiresAt` — the link no longer accepts a response.
  expired,

  /// No `NpsSurveyRequest` was ever found for this token (unknown/malformed
  /// link).
  notFound,
}

extension NpsSurveyOutcomeCode on NpsSurveyOutcome {
  /// The exact string `getNpsSurveyByToken`/`submitNpsResponse` (Cloud
  /// Functions) use on the wire.
  String get code => switch (this) {
    NpsSurveyOutcome.pending => 'pending',
    NpsSurveyOutcome.answered => 'answered',
    NpsSurveyOutcome.expired => 'expired',
    NpsSurveyOutcome.notFound => 'notFound',
  };

  static NpsSurveyOutcome fromCode(String code) => switch (code) {
    'pending' => NpsSurveyOutcome.pending,
    'answered' => NpsSurveyOutcome.answered,
    'expired' => NpsSurveyOutcome.expired,
    'notFound' => NpsSurveyOutcome.notFound,
    _ => NpsSurveyOutcome.notFound,
  };
}
