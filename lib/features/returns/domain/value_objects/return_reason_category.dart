/// Categorized reason a `ReturnRequest` (TASK-199, EPIC-30) was opened for —
/// `tasks.md`'s own "motivo obrigatório categorizado — ex.: defeito, troca
/// de decisão, erro de pedido". [ReturnRequest.reasonDetails] may add free
/// text context, but it never substitutes for one of these values
/// (`tasks.md`: "texto livre nunca substitui a categoria"), and
/// `createReturnRequest` (Cloud Function) independently re-validates it is
/// always one of these — never trusted from the client alone.
enum ReturnReasonCategory {
  defect,
  wrongItem,
  changeOfMind,
  orderError,
  other;

  static ReturnReasonCategory fromCode(String code) => switch (code) {
    'defect' => ReturnReasonCategory.defect,
    'wrong_item' => ReturnReasonCategory.wrongItem,
    'change_of_mind' => ReturnReasonCategory.changeOfMind,
    'order_error' => ReturnReasonCategory.orderError,
    _ => ReturnReasonCategory.other,
  };

  String get code => switch (this) {
    ReturnReasonCategory.defect => 'defect',
    ReturnReasonCategory.wrongItem => 'wrong_item',
    ReturnReasonCategory.changeOfMind => 'change_of_mind',
    ReturnReasonCategory.orderError => 'order_error',
    ReturnReasonCategory.other => 'other',
  };

  /// Human-readable label (pt-BR) — reused by every screen that renders a
  /// [ReturnReasonCategory] so the wording never drifts apart.
  String get label => switch (this) {
    ReturnReasonCategory.defect => 'Defeito',
    ReturnReasonCategory.wrongItem => 'Item errado',
    ReturnReasonCategory.changeOfMind => 'Troca de decisão',
    ReturnReasonCategory.orderError => 'Erro no pedido',
    ReturnReasonCategory.other => 'Outro motivo',
  };
}
