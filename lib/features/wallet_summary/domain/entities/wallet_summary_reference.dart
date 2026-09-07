/// One data point the generated wallet summary text cited as `[refs: code]`
/// (TASK-186, EPIC-28) — rendered by the UI as an expandable citation next
/// to the sentence(s) that reference it, so every claim in
/// [WalletSummary.summaryText] stays traceable back to the exact
/// already-computed backend number that backs it. Never constructed
/// client-side: always exactly what `generateWalletSummary`'s own
/// server-side validation already confirmed exists in the payload it built.
final class WalletSummaryReference {
  const WalletSummaryReference({
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
