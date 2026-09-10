/// Categorized reason an `ExchangeRequest` (TASK-200, EPIC-30) was opened
/// for — mirrors `ReturnReasonCategory`'s own "motivo obrigatório
/// categorizado" contract (TASK-199), with a troca-specific vocabulary
/// (tamanho errado, preferência de cor) in place of devolução's own.
/// `ExchangeRequest.reasonDetails` may add free text context, but it never
/// substitutes for one of these values, and `createExchangeRequest` (Cloud
/// Function) independently re-validates it is always one of these — never
/// trusted from the client alone.
enum ExchangeReasonCategory {
  sizeIssue,
  colorPreference,
  defect,
  wrongItem,
  other;

  static ExchangeReasonCategory fromCode(String code) => switch (code) {
    'size_issue' => ExchangeReasonCategory.sizeIssue,
    'color_preference' => ExchangeReasonCategory.colorPreference,
    'defect' => ExchangeReasonCategory.defect,
    'wrong_item' => ExchangeReasonCategory.wrongItem,
    _ => ExchangeReasonCategory.other,
  };

  String get code => switch (this) {
    ExchangeReasonCategory.sizeIssue => 'size_issue',
    ExchangeReasonCategory.colorPreference => 'color_preference',
    ExchangeReasonCategory.defect => 'defect',
    ExchangeReasonCategory.wrongItem => 'wrong_item',
    ExchangeReasonCategory.other => 'other',
  };

  /// Human-readable label (pt-BR) — reused by every screen that renders an
  /// [ExchangeReasonCategory] so the wording never drifts apart.
  String get label => switch (this) {
    ExchangeReasonCategory.sizeIssue => 'Tamanho errado',
    ExchangeReasonCategory.colorPreference => 'Preferência de cor',
    ExchangeReasonCategory.defect => 'Defeito',
    ExchangeReasonCategory.wrongItem => 'Item errado',
    ExchangeReasonCategory.other => 'Outro motivo',
  };
}
