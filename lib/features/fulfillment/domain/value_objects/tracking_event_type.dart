/// Milestone a `TrackingEvent` carries (TASK-214, EPIC-32). Mirrors
/// `functions/src/fulfillment/fulfillment-shared.ts`'s own
/// `TrackingEventType` union 1:1. [adjustment] never moves `Shipment.status`
/// by itself — it only ever carries a correction note tied back to another
/// event (`TrackingEvent.correctionOfEventId`), the append-only "correção
/// nunca sobrescreve histórico" rule this task requires.
enum TrackingEventType {
  pickingStarted,
  packed,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  partiallyDelivered,
  returnedToCarrier,
  adjustment;

  String get code {
    return switch (this) {
      TrackingEventType.pickingStarted => 'picking_started',
      TrackingEventType.packed => 'packed',
      TrackingEventType.shipped => 'shipped',
      TrackingEventType.inTransit => 'in_transit',
      TrackingEventType.outForDelivery => 'out_for_delivery',
      TrackingEventType.delivered => 'delivered',
      TrackingEventType.partiallyDelivered => 'partially_delivered',
      TrackingEventType.returnedToCarrier => 'returned_to_carrier',
      TrackingEventType.adjustment => 'adjustment',
    };
  }

  static TrackingEventType fromCode(String code) {
    return switch (code) {
      'picking_started' => TrackingEventType.pickingStarted,
      'packed' => TrackingEventType.packed,
      'shipped' => TrackingEventType.shipped,
      'in_transit' => TrackingEventType.inTransit,
      'out_for_delivery' => TrackingEventType.outForDelivery,
      'delivered' => TrackingEventType.delivered,
      'partially_delivered' => TrackingEventType.partiallyDelivered,
      'returned_to_carrier' => TrackingEventType.returnedToCarrier,
      'adjustment' => TrackingEventType.adjustment,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown TrackingEventType code',
      ),
    };
  }

  String get label {
    return switch (this) {
      TrackingEventType.pickingStarted => 'Separação iniciada',
      TrackingEventType.packed => 'Embalado',
      TrackingEventType.shipped => 'Expedido',
      TrackingEventType.inTransit => 'Em trânsito',
      TrackingEventType.outForDelivery => 'Saiu para entrega',
      TrackingEventType.delivered => 'Entregue',
      TrackingEventType.partiallyDelivered => 'Entrega parcial',
      TrackingEventType.returnedToCarrier => 'Devolvido à transportadora',
      TrackingEventType.adjustment => 'Ajuste/correção',
    };
  }
}

/// Origin of one `TrackingEvent` (TASK-214): `webhook` (integração externa/
/// transportadora), `manual` (lançamento por vendedor/gestor) or `admin`
/// (lançamento administrativo por OWNER/ADMIN).
enum TrackingEventSource {
  webhook,
  manual,
  admin;

  String get code {
    return switch (this) {
      TrackingEventSource.webhook => 'webhook',
      TrackingEventSource.manual => 'manual',
      TrackingEventSource.admin => 'admin',
    };
  }

  static TrackingEventSource fromCode(String code) {
    return switch (code) {
      'webhook' => TrackingEventSource.webhook,
      'manual' => TrackingEventSource.manual,
      'admin' => TrackingEventSource.admin,
      _ => throw ArgumentError.value(
        code,
        'code',
        'Unknown TrackingEventSource code',
      ),
    };
  }
}
