import '../entities/order_item.dart';

/// Pure merge/edit rules for the items of an `Order` draft (EPIC-13,
/// TASK-097): adding products from the catalog, editing a typed quantity or
/// removing a line already on the draft.
///
/// Deliberately holds no dependency on Flutter, Firebase, Drift or any other
/// feature — `OrderDraftBloc` (in-memory edits) and
/// `AddItemsToOrderDraftUseCase` (persisted additions coming back from the
/// catalog flow) both call the very same functions here instead of each
/// re-implementing "how does a quantity change affect `OrderItem.subtotal`".
final class OrderItemEditor {
  const OrderItemEditor._();

  /// Merges [additions] into [items]: a variant already present on the order
  /// (matched by [OrderItem.variantId]) has its quantity summed and its
  /// [OrderItem.unitPrice] refreshed to the addition's own — the price the
  /// seller was just shown for that fresh "add" action — never a previously
  /// captured, possibly stale price for the same session. A variant not yet
  /// present is appended as-is.
  static List<OrderItem> withAddedItems(
    List<OrderItem> items,
    List<OrderItem> additions,
  ) {
    final result = List<OrderItem>.of(items);
    for (final addition in additions) {
      final existingIndex = result.indexWhere(
        (item) => item.variantId == addition.variantId,
      );
      if (existingIndex == -1) {
        result.add(addition);
        continue;
      }
      final existing = result[existingIndex];
      final mergedQuantity = existing.quantity + addition.quantity;
      result[existingIndex] = existing.copyWith(
        quantity: mergedQuantity,
        unitPrice: addition.unitPrice,
        subtotal: _subtotalFor(
          quantity: mergedQuantity,
          unitPrice: addition.unitPrice,
          discountAmount: existing.discountAmount,
          surchargeAmount: existing.surchargeAmount,
        ),
      );
    }
    return List<OrderItem>.unmodifiable(result);
  }

  /// Sets the item identified by [itemId] to [quantity], recomputing its
  /// [OrderItem.subtotal]. A [quantity] of zero or less removes the line
  /// entirely — same "0 means gone" convention the catalog's own
  /// `ProductDetailBloc.quantitiesByVariantId` already follows, so the
  /// stepper's decrement-to-zero affordance behaves the same way in both
  /// places.
  static List<OrderItem> withUpdatedQuantity(
    List<OrderItem> items, {
    required String itemId,
    required int quantity,
  }) {
    if (quantity <= 0) return withRemovedItem(items, itemId: itemId);
    return List<OrderItem>.unmodifiable(<OrderItem>[
      for (final item in items)
        if (item.id == itemId)
          item.copyWith(
            quantity: quantity,
            subtotal: _subtotalFor(
              quantity: quantity,
              unitPrice: item.unitPrice,
              discountAmount: item.discountAmount,
              surchargeAmount: item.surchargeAmount,
            ),
          )
        else
          item,
    ]);
  }

  /// Removes the item identified by [itemId], if any.
  static List<OrderItem> withRemovedItem(
    List<OrderItem> items, {
    required String itemId,
  }) {
    return List<OrderItem>.unmodifiable(
      items.where((item) => item.id != itemId),
    );
  }

  /// `quantity * unitPrice` adjusted by [discountAmount]/[surchargeAmount],
  /// per `OrderItem.subtotal`'s own documented formula — never negative
  /// (a discount can never make a line's captured subtotal read as if the
  /// seller owed the customer money).
  static double _subtotalFor({
    required int quantity,
    required double unitPrice,
    required double discountAmount,
    required double surchargeAmount,
  }) {
    final net = (quantity * unitPrice) - discountAmount + surchargeAmount;
    return net < 0 ? 0 : net;
  }
}
