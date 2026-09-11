/// One item inside a `ShipmentPackage` (TASK-214, EPIC-32) — denormalized
/// from the original `Order.items` entry it references ([orderItemId]) at
/// the moment the romaneio was created, same "read the order's own persisted
/// items, freeze them into this record" precedent `ReturnRequestItem`
/// already sets.
final class ShipmentPackageItem {
  const ShipmentPackageItem({
    required this.orderItemId,
    required this.productId,
    required this.variantId,
    required this.quantity,
  });

  final String orderItemId;
  final String productId;
  final String variantId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShipmentPackageItem &&
          other.orderItemId == orderItemId &&
          other.productId == productId &&
          other.variantId == variantId &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(orderItemId, productId, variantId, quantity);
}

/// Minimal shape a caller submits when reporting an item actually delivered
/// this event (TASK-214) — quantity for *this* event only, never cumulative;
/// the server (`applyDeliveredItems`) accumulates it against the shipment's
/// own ledger.
final class DeliveredItem {
  const DeliveredItem({required this.orderItemId, required this.quantity});

  final String orderItemId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeliveredItem &&
          other.orderItemId == orderItemId &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(orderItemId, quantity);
}
