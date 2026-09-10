/// The result `submitNpsResponse` (Cloud Function) resolves a submission
/// into — never an exception for an ordinary "cannot be answered right now"
/// case (already-answered/expired/not-found), same "outcome, not a thrown
/// error" contract [NpsSurveyPreview] itself already follows.
enum NpsResponseSubmissionOutcome {
  accepted,
  alreadyAnswered,
  expired,
  notFound,
}

final class NpsResponseSubmissionResult {
  const NpsResponseSubmissionResult({required this.outcome});

  final NpsResponseSubmissionOutcome outcome;
}
