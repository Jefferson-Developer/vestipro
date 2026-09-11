import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/backorder/backorder.dart';

BackorderRequest _build({
  required BackorderStatus status,
  int quantity = 10,
  int fulfilledQuantity = 0,
}) {
  return BackorderRequest(
    id: 'backorder-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    customerId: 'customer-1',
    productId: 'product-1',
    variantId: 'variant-1',
    quantity: quantity,
    fulfilledQuantity: fulfilledQuantity,
    quantityAtRequest: 2,
    origin: BackorderOrigin.catalog,
    priority: BackorderPriority.normal,
    sellerId: 'seller-1',
    status: status,
    requestedBy: 'seller-1',
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('BackorderRequest.remainingQuantity', () {
    test('is the full quantity when nothing was fulfilled yet', () {
      final backorder = _build(status: BackorderStatus.queued, quantity: 10);
      expect(backorder.remainingQuantity, 10);
    });

    test('subtracts fulfilledQuantity once partially/fully converted', () {
      final backorder = _build(
        status: BackorderStatus.converted,
        quantity: 10,
        fulfilledQuantity: 10,
      );
      expect(backorder.remainingQuantity, 0);
    });
  });

  group('BackorderRequest.isOpen', () {
    test('mirrors BackorderStatus.isOpen', () {
      for (final status in BackorderStatus.values) {
        expect(_build(status: status).isOpen, status.isOpen);
      }
    });
  });

  group('BackorderRequest equality', () {
    test('two requests with the same fields are equal', () {
      final a = _build(status: BackorderStatus.queued);
      final b = _build(status: BackorderStatus.queued);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('requests with a different status are not equal', () {
      final a = _build(status: BackorderStatus.queued);
      final b = _build(status: BackorderStatus.cancelled);
      expect(a, isNot(equals(b)));
    });
  });
}
