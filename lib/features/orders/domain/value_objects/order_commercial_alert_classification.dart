/// Which "pedido com problema" situation (TASK-153, EPIC-19) triggered a
/// commercial notification for an `Order` — mirrors the same "one enum per
/// alert kind" shape `TargetAlertClassification` (TASK-149) already
/// established.
enum OrderCommercialAlertClassification {
  /// The order was routed back to the seller with `Order.rejectionReason`
  /// set (`OrderStatus.rejected`).
  rejected,

  /// The order failed to reach the backend after being created/edited
  /// offline (`OrderSyncStatus.failed`) — a real risk of losing the pedido
  /// entirely if the seller never notices and retries.
  criticalSyncFailure,
}
