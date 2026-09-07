import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderContentHasher', () {
    const hasher = OrderContentHasher();

    test('returns the same hash for the exact same order content', () {
      final order = _order();

      expect(hasher.hash(order), hasher.hash(order.copyWith()));
    });

    test('returns a different hash when an item quantity changes', () {
      final order = _order();
      final changed = order.copyWith(
        items: [order.items.single.copyWith(quantity: 3)],
      );

      expect(hasher.hash(order), isNot(hasher.hash(changed)));
    });

    test('returns a different hash when discountAmount changes', () {
      final order = _order();
      final changed = order.copyWith(discountAmount: 10);

      expect(hasher.hash(order), isNot(hasher.hash(changed)));
    });

    test('returns the same hash regardless of status/statusHistory/syncStatus '
        '(audit-only fields never affect the signable content)', () {
      final order = _order();
      final advanced = order.copyWith(
        status: OrderStatus.invoiced,
        statusHistory: [
          OrderStatusHistoryEntry(
            newStatus: OrderStatus.invoiced,
            changedAt: DateTime.utc(2026, 6, 2),
            actorId: 'seller-1',
          ),
        ],
        syncStatus: OrderSyncStatus.synced,
      );

      expect(hasher.hash(order), hasher.hash(advanced));
    });

    test('a whole monetary value never changes the hash purely because of how '
        'it would otherwise serialize as a JSON number (the exact cross-'
        'language pitfall this hasher works around)', () {
      final whole = _order().copyWith(shippingAmount: 10);
      final fractional = _order().copyWith(shippingAmount: 10.01);

      expect(hasher.hash(whole), isNot(hasher.hash(fractional)));
      // Same whole value hashed twice must still be perfectly stable.
      expect(
        hasher.hash(whole),
        hasher.hash(_order().copyWith(shippingAmount: 10)),
      );
    });
  });
}

Order _order() {
  final now = DateTime.utc(2026, 6, 1);
  return Order(
    id: 'order-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    branchId: 'branch-1',
    customerId: 'customer-1',
    sellerId: 'seller-1',
    orderNumber: '000001',
    deliveryAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    billingAddress: const OrderAddress(
      street: 'Rua das Flores',
      city: 'Blumenau',
      state: 'SC',
      zipCode: '89010000',
    ),
    priceListId: 'price-list-1',
    paymentTermId: 'term-1',
    items: [
      const OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 2,
        unitPrice: 88,
        discountAmount: 12,
        subtotal: 176,
      ),
    ],
    discountAmount: 24,
    status: OrderStatus.submitted,
    createdAt: now,
    createdBy: 'seller-1',
    updatedAt: now,
    updatedBy: 'seller-1',
    version: 1,
    syncStatus: OrderSyncStatus.pending,
  );
}
