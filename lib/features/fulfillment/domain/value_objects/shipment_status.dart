/// Status of a `Shipment`/romaneio (TASK-214, EPIC-32 — expedição, romaneio,
/// tracking e ocorrências). `pending` is the initial status `createShipment`
/// (Cloud Function) writes; every other value is only ever reached by a
/// `TrackingEvent` landing (`registerTrackingEvent`/
/// `handleShipmentTrackingWebhook`) — never set directly by the UI.
enum ShipmentStatus {
  pending,
  picking,
  packed,
  shipped,
  inTransit,
  outForDelivery,
  partiallyDelivered,
  delivered,
  returned,
  cancelled;

  /// The exact string persisted in Firestore — mirrors
  /// `functions/src/fulfillment/fulfillment-shared.ts`'s own `ShipmentStatus`
  /// union 1:1.
  String get code {
    return switch (this) {
      ShipmentStatus.pending => 'pending',
      ShipmentStatus.picking => 'picking',
      ShipmentStatus.packed => 'packed',
      ShipmentStatus.shipped => 'shipped',
      ShipmentStatus.inTransit => 'in_transit',
      ShipmentStatus.outForDelivery => 'out_for_delivery',
      ShipmentStatus.partiallyDelivered => 'partially_delivered',
      ShipmentStatus.delivered => 'delivered',
      ShipmentStatus.returned => 'returned',
      ShipmentStatus.cancelled => 'cancelled',
    };
  }

  static ShipmentStatus fromCode(String code) {
    return switch (code) {
      'pending' => ShipmentStatus.pending,
      'picking' => ShipmentStatus.picking,
      'packed' => ShipmentStatus.packed,
      'shipped' => ShipmentStatus.shipped,
      'in_transit' => ShipmentStatus.inTransit,
      'out_for_delivery' => ShipmentStatus.outForDelivery,
      'partially_delivered' => ShipmentStatus.partiallyDelivered,
      'delivered' => ShipmentStatus.delivered,
      'returned' => ShipmentStatus.returned,
      'cancelled' => ShipmentStatus.cancelled,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown ShipmentStatus code',
      ),
    };
  }

  /// Whether this status still represents an active, in-progress expedição —
  /// mirrors `OPEN_SHIPMENT_STATUSES` (`fulfillment-shared.ts`), the exact
  /// set `detectShipmentDelays` scans.
  bool get isOpen =>
      this != ShipmentStatus.delivered &&
      this != ShipmentStatus.returned &&
      this != ShipmentStatus.cancelled;

  String get label {
    return switch (this) {
      ShipmentStatus.pending => 'Aguardando separação',
      ShipmentStatus.picking => 'Em separação',
      ShipmentStatus.packed => 'Embalado',
      ShipmentStatus.shipped => 'Expedido',
      ShipmentStatus.inTransit => 'Em trânsito',
      ShipmentStatus.outForDelivery => 'Saiu para entrega',
      ShipmentStatus.partiallyDelivered => 'Entrega parcial',
      ShipmentStatus.delivered => 'Entregue',
      ShipmentStatus.returned => 'Devolvido pela transportadora',
      ShipmentStatus.cancelled => 'Cancelado',
    };
  }
}
