/// One line of a `ReturnRequest` (TASK-199, EPIC-30) — denormalized from the
/// original `Order.items` entry it references ([orderItemId]) at the moment
/// the devolução was requested, so the request's own history never drifts
/// even if the order's pricing/catalog data changes later.
final class ReturnRequestItem {
  const ReturnRequestItem({
    required this.orderItemId,
    required this.productId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.warehouseId,
  });

  final String orderItemId;
  final String productId;
  final String variantId;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  /// The exact warehouse this quantity was originally decremented from at
  /// submission time (TASK-101) — `null` only for orders predating that
  /// denormalization, in which case `resolveReturnRequest` falls back to any
  /// balance already tracking [variantId].
  final String? warehouseId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReturnRequestItem &&
          other.orderItemId == orderItemId &&
          other.productId == productId &&
          other.variantId == variantId &&
          other.quantity == quantity &&
          other.unitPrice == unitPrice &&
          other.subtotal == subtotal &&
          other.warehouseId == warehouseId);

  @override
  int get hashCode => Object.hash(
    orderItemId,
    productId,
    variantId,
    quantity,
    unitPrice,
    subtotal,
    warehouseId,
  );
}

/// One requested item (TASK-199) — the minimal shape `createReturnRequest`
/// needs from the caller; every other [ReturnRequestItem] field is always
/// resolved/revalidated server-side from the order's own persisted data,
/// never accepted from the client.
final class ReturnRequestItemInput {
  const ReturnRequestItemInput({
    required this.orderItemId,
    required this.quantity,
  });

  final String orderItemId;
  final int quantity;
}
