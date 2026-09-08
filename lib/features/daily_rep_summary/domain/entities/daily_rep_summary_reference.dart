/// One data point the generated daily summary text cited as `[refs: code]`
/// (TASK-188, EPIC-28) — rendered by the UI as an expandable citation next to
/// the sentence(s) that reference it, so every claim in
/// [DailyRepSummary.summaryText] stays traceable back to the exact
/// already-computed backend number that backs it. Never constructed
/// client-side: always exactly what `generateDailyRepSummary`'s own
/// server-side validation already confirmed exists in the payload it built.
final class DailyRepSummaryReference {
  const DailyRepSummaryReference({
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
