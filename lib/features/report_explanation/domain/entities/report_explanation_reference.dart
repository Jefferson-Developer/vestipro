/// One data point the generated report explanation text cited as
/// `[refs: code]` (TASK-189, EPIC-28) — rendered by the UI as an expandable
/// citation next to the sentence(s) that reference it, so every claim in
/// [ReportExplanationReference] stays traceable back to the exact
/// already-computed backend number that backs it. Never constructed
/// client-side: always exactly what `explainReport`'s own server-side
/// validation already confirmed exists in the payload it built (the same
/// server-derived aggregation `executeReportQuery`/`exportReportToCsv`
/// already use — never a value the client sent).
final class ReportExplanationReference {
  const ReportExplanationReference({
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
