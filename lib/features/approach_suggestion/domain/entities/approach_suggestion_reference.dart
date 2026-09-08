/// One data point the generated approach suggestion cited as `[refs: code]`
/// (TASK-187, EPIC-28) — rendered by the UI as an expandable citation next
/// to the sentence(s) that reference it, so every claim in
/// [ApproachSuggestion.suggestedText] stays traceable back to an
/// already-known fact (a real order, CRM activity or insight) the server
/// already verified exists. Never constructed client-side: always exactly
/// what `suggestApproach`'s own server-side validation already confirmed
/// exists in the payload it built.
final class ApproachSuggestionReference {
  const ApproachSuggestionReference({
    required this.code,
    required this.label,
    required this.value,
    this.unit,
  });

  final String code;
  final String label;
  final String value;
  final String? unit;
}
