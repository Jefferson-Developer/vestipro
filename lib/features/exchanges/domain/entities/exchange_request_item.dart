/// One line of an `ExchangeRequest` (TASK-200, EPIC-30) — the original
/// (origem) product/variant/quantity being returned, paired with the
/// destination variant (mesma produto, cor/tamanho diferente) requested in
/// its place. [originUnitPrice] is denormalized from the original `Order`
/// item at the moment the troca was requested (frozen, exactly what the
/// customer already paid) — [destinationVariantId]'s own price is *never*
/// frozen here: it is only ever priced by the pricing engine at approval
/// time (`resolveExchangeRequest`), so this entity intentionally carries no
/// destination price field at all.
final class ExchangeRequestItem {
  const ExchangeRequestItem({
    required this.orderItemId,
    required this.originProductId,
    required this.originVariantId,
    required this.originUnitPrice,
    required this.destinationVariantId,
    required this.destinationProductId,
    required this.quantity,
  });

  final String orderItemId;
  final String originProductId;
  final String originVariantId;
  final double originUnitPrice;
  final String destinationVariantId;
  final String destinationProductId;
  final int quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRequestItem &&
          other.orderItemId == orderItemId &&
          other.originProductId == originProductId &&
          other.originVariantId == originVariantId &&
          other.originUnitPrice == originUnitPrice &&
          other.destinationVariantId == destinationVariantId &&
          other.destinationProductId == destinationProductId &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(
    orderItemId,
    originProductId,
    originVariantId,
    originUnitPrice,
    destinationVariantId,
    destinationProductId,
    quantity,
  );
}

/// One requested item (TASK-200) — the minimal shape `createExchangeRequest`
/// needs from the caller; every other [ExchangeRequestItem] field is always
/// resolved/revalidated server-side from the order's own persisted data and
/// from the destination variant's own catalog record, never accepted from
/// the client.
final class ExchangeRequestItemInput {
  const ExchangeRequestItemInput({
    required this.orderItemId,
    required this.destinationVariantId,
    required this.quantity,
  });

  final String orderItemId;
  final String destinationVariantId;
  final int quantity;
}
