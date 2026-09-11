/// Every status a `BackorderRequest` (TASK-215, EPIC-32) may carry — mirrors
/// 1:1 the string codes the Cloud Functions under `functions/src/backorder/`
/// persist (`backorder-shared.ts`'s own `BackorderStatus`), so a Dart-side
/// switch on this enum never drifts silently from the server's own status
/// machine.
enum BackorderStatus {
  /// Just created, still being processed synchronously by
  /// `createBackorderRequest` — never actually observed at rest in
  /// Firestore (the callable always resolves it to [queued] or
  /// [awaitingApproval] before returning), kept only so this enum's own
  /// `values` stays a complete mirror of the server-side union.
  requested,

  /// Above the organization's own auto-approve quantity limit
  /// (`tasks.md`: "Cliente/vendedor não pode criar backorder acima de
  /// limites configurados sem aprovação") — parked until
  /// `decideBackorderApproval` runs.
  awaitingApproval,

  /// Cleared for atendimento — either auto-queued at creation (within the
  /// limit) or approved by a gestor. Sits in the priorized fila until stock
  /// becomes available or it is converted/cancelled.
  queued,

  /// The stock-availability watcher (`notifyBackordersOnStockAvailable`)
  /// found enough sellable quantity for this request right now — a
  /// heads-up ("previsão"/disponibilidade aparente), never a firm reserva:
  /// `convertBackorderToOrder` still revalidates for real at conversion
  /// time.
  readyToFulfill,

  /// Linked to an already-submitted pedido that covers its pending
  /// quantity (`convertBackorderToOrder`) — terminal, final.
  converted,

  /// Decided negatively by a gestor (`decideBackorderApproval`) — terminal,
  /// final.
  rejected,

  /// Cancelled by whoever could act on it before ever being
  /// converted/rejected (`cancelBackorderRequest`) — terminal, final.
  cancelled;

  /// The exact string persisted in Firestore — mirrors
  /// `functions/src/backorder/backorder-shared.ts`'s own `BackorderStatus`
  /// union 1:1.
  String get code {
    return switch (this) {
      BackorderStatus.requested => 'requested',
      BackorderStatus.awaitingApproval => 'awaiting_approval',
      BackorderStatus.queued => 'queued',
      BackorderStatus.readyToFulfill => 'ready_to_fulfill',
      BackorderStatus.converted => 'converted',
      BackorderStatus.rejected => 'rejected',
      BackorderStatus.cancelled => 'cancelled',
    };
  }

  static BackorderStatus fromCode(String code) {
    return switch (code) {
      'requested' => BackorderStatus.requested,
      'awaiting_approval' => BackorderStatus.awaitingApproval,
      'queued' => BackorderStatus.queued,
      'ready_to_fulfill' => BackorderStatus.readyToFulfill,
      'converted' => BackorderStatus.converted,
      'rejected' => BackorderStatus.rejected,
      'cancelled' => BackorderStatus.cancelled,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown BackorderStatus code',
      ),
    };
  }

  /// Still "in flight" — never yet converted/rejected/cancelled — mirrors
  /// `backorder-shared.ts`'s own `OPEN_BACKORDER_STATUSES`. The only
  /// statuses `cancelBackorderRequest` ever accepts acting upon.
  bool get isOpen => switch (this) {
    BackorderStatus.requested ||
    BackorderStatus.awaitingApproval ||
    BackorderStatus.queued ||
    BackorderStatus.readyToFulfill => true,
    BackorderStatus.converted ||
    BackorderStatus.rejected ||
    BackorderStatus.cancelled => false,
  };

  /// Eligible for the priorized atendimento queue proper — mirrors
  /// `backorder-shared.ts`'s own `QUEUEABLE_BACKORDER_STATUSES`.
  /// [BackorderStatus.awaitingApproval] is deliberately excluded: it only
  /// ever shows up in a separate "aguardando aprovação" inbox.
  bool get isQueueable =>
      this == BackorderStatus.queued || this == BackorderStatus.readyToFulfill;

  String get label {
    return switch (this) {
      BackorderStatus.requested => 'Solicitado',
      BackorderStatus.awaitingApproval => 'Aguardando aprovação',
      BackorderStatus.queued => 'Na fila de atendimento',
      BackorderStatus.readyToFulfill => 'Estoque disponível',
      BackorderStatus.converted => 'Convertido em pedido',
      BackorderStatus.rejected => 'Recusado',
      BackorderStatus.cancelled => 'Cancelado',
    };
  }
}
