/// Every event type a pedido's pós-venda timeline (TASK-201, EPIC-30) may
/// ever carry, mirroring exactly `PostSaleEventType`
/// (`functions/src/after_sales/after-sales-shared.ts`). The six manual
/// milestones ([isManual]) are registered by vendedor/suporte via
/// `RegisterPostSaleEventUseCase`; the four system ones are only ever
/// appended by the Cloud Functions behind devoluções/trocas (TASK-199/
/// TASK-200) themselves — never selectable from the manual registration
/// form, reusing that exact same modelagem instead of duplicating it
/// (`tasks.md`: "Vincular devoluções/trocas... como eventos na mesma
/// timeline").
enum PostSaleEventType {
  dispatched,
  inTransit,
  delivered,
  problemReported,
  inResolution,
  resolved,
  returnRequested,
  returnResolved,
  exchangeRequested,
  exchangeResolved;

  static PostSaleEventType fromCode(String code) => switch (code) {
    'dispatched' => PostSaleEventType.dispatched,
    'in_transit' => PostSaleEventType.inTransit,
    'delivered' => PostSaleEventType.delivered,
    'problem_reported' => PostSaleEventType.problemReported,
    'in_resolution' => PostSaleEventType.inResolution,
    'resolved' => PostSaleEventType.resolved,
    'return_requested' => PostSaleEventType.returnRequested,
    'return_resolved' => PostSaleEventType.returnResolved,
    'exchange_requested' => PostSaleEventType.exchangeRequested,
    'exchange_resolved' => PostSaleEventType.exchangeResolved,
    _ => PostSaleEventType.dispatched,
  };

  String get code => switch (this) {
    PostSaleEventType.dispatched => 'dispatched',
    PostSaleEventType.inTransit => 'in_transit',
    PostSaleEventType.delivered => 'delivered',
    PostSaleEventType.problemReported => 'problem_reported',
    PostSaleEventType.inResolution => 'in_resolution',
    PostSaleEventType.resolved => 'resolved',
    PostSaleEventType.returnRequested => 'return_requested',
    PostSaleEventType.returnResolved => 'return_resolved',
    PostSaleEventType.exchangeRequested => 'exchange_requested',
    PostSaleEventType.exchangeResolved => 'exchange_resolved',
  };

  String get label => switch (this) {
    PostSaleEventType.dispatched => 'Despachado',
    PostSaleEventType.inTransit => 'Em trânsito',
    PostSaleEventType.delivered => 'Entregue',
    PostSaleEventType.problemReported => 'Problema reportado',
    PostSaleEventType.inResolution => 'Em resolução',
    PostSaleEventType.resolved => 'Resolvido',
    PostSaleEventType.returnRequested => 'Devolução solicitada',
    PostSaleEventType.returnResolved => 'Devolução decidida',
    PostSaleEventType.exchangeRequested => 'Troca solicitada',
    PostSaleEventType.exchangeResolved => 'Troca decidida',
  };

  /// Whether this type may ever be selected on the manual registration form
  /// — mirrors exactly `MANUAL_POST_SALE_EVENT_TYPES`
  /// (`functions/src/after_sales/after-sales-shared.ts`), independently
  /// re-validated there (never trusted from the client alone).
  bool get isManual => switch (this) {
    PostSaleEventType.dispatched ||
    PostSaleEventType.inTransit ||
    PostSaleEventType.delivered ||
    PostSaleEventType.problemReported ||
    PostSaleEventType.inResolution ||
    PostSaleEventType.resolved => true,
    PostSaleEventType.returnRequested ||
    PostSaleEventType.returnResolved ||
    PostSaleEventType.exchangeRequested ||
    PostSaleEventType.exchangeResolved => false,
  };

  /// Whether registering this type requires a non-empty `description`
  /// (`tasks.md`/TASK-201: "Registro manual de problema exige descrição
  /// mínima obrigatória — nunca um evento vazio de 'problema'") —
  /// re-validated server-side by `requirePostSaleDescription`, never trusted
  /// from the client alone.
  bool get requiresDescription => this == PostSaleEventType.problemReported;

  /// Every manual milestone, in registration-form display order.
  static List<PostSaleEventType> get manualValues =>
      values.where((type) => type.isManual).toList(growable: false);
}

/// Where a `PostSaleEvent` came from (TASK-201) — `manual` (vendedor/
/// suporte, via `registerPostSaleEvent`) or `system` (auto-appended by a
/// devolução/troca Cloud Function, TASK-199/TASK-200).
enum PostSaleEventSource {
  manual,
  system;

  static PostSaleEventSource fromCode(String code) => switch (code) {
    'system' => PostSaleEventSource.system,
    _ => PostSaleEventSource.manual,
  };

  String get code => switch (this) {
    PostSaleEventSource.manual => 'manual',
    PostSaleEventSource.system => 'system',
  };
}
