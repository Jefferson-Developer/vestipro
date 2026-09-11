/// Where a `BackorderRequest` (TASK-215, EPIC-32) originated from — mirrors
/// 1:1 `functions/src/backorder/backorder-shared.ts`'s own `BackorderOrigin`
/// union, purely informational (never gates a rule by itself).
enum BackorderOrigin {
  /// Solicitado a partir do catálogo/grade comercial, sem um pedido em
  /// andamento por trás (produto/variante ficou sem estoque pronta entrega
  /// suficiente durante a navegação).
  catalog,

  /// Solicitado a partir de um pedido já em andamento — o item ficou
  /// parcialmente ou totalmente sem estoque no momento da montagem/revisão
  /// do pedido ([BackorderRequest.relatedOrderId] sempre presente).
  order,

  /// Solicitado dentro de um programa de pré-venda/pre-book (TASK-210) — a
  /// própria coleção ainda não tem estoque físico disponível.
  preBook,

  /// Registrado manualmente por um vendedor/gestor em nome do cliente
  /// (ex.: durante uma visita, sem acesso ao catálogo no momento).
  manual;

  /// The exact string persisted in Firestore.
  String get code {
    return switch (this) {
      BackorderOrigin.catalog => 'catalog',
      BackorderOrigin.order => 'order',
      BackorderOrigin.preBook => 'pre_book',
      BackorderOrigin.manual => 'manual',
    };
  }

  static BackorderOrigin fromCode(String code) {
    return switch (code) {
      'catalog' => BackorderOrigin.catalog,
      'order' => BackorderOrigin.order,
      'pre_book' => BackorderOrigin.preBook,
      'manual' => BackorderOrigin.manual,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown BackorderOrigin code',
      ),
    };
  }

  String get label {
    return switch (this) {
      BackorderOrigin.catalog => 'Catálogo',
      BackorderOrigin.order => 'Pedido',
      BackorderOrigin.preBook => 'Pré-venda',
      BackorderOrigin.manual => 'Manual',
    };
  }
}
