import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/fulfillment/fulfillment.dart';

Shipment _build({
  required ShipmentStatus status,
  Map<String, int> deliveredQuantities = const <String, int>{},
}) {
  return Shipment(
    id: 'shipment-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    orderNumber: '1001',
    customerId: 'customer-1',
    sellerId: 'seller-1',
    status: status,
    hasOpenIssue: false,
    packages: const <ShipmentPackage>[
      ShipmentPackage(
        packageNumber: 1,
        items: <ShipmentPackageItem>[
          ShipmentPackageItem(
            orderItemId: 'item-1',
            productId: 'product-1',
            variantId: 'variant-1',
            quantity: 10,
          ),
        ],
      ),
      ShipmentPackage(
        packageNumber: 2,
        items: <ShipmentPackageItem>[
          ShipmentPackageItem(
            orderItemId: 'item-2',
            productId: 'product-2',
            variantId: 'variant-2',
            quantity: 5,
          ),
        ],
      ),
    ],
    deliveredQuantities: deliveredQuantities,
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  group('Shipment.totalQuantity', () {
    test('sums quantity across every package', () {
      final shipment = _build(status: ShipmentStatus.pending);
      expect(shipment.totalQuantity, 15);
    });
  });

  group('Shipment.totalDeliveredQuantity', () {
    test('sums the delivered ledger across every item', () {
      final shipment = _build(
        status: ShipmentStatus.partiallyDelivered,
        deliveredQuantities: const <String, int>{'item-1': 10, 'item-2': 2},
      );
      expect(shipment.totalDeliveredQuantity, 12);
    });

    test('is zero when nothing has been delivered yet', () {
      final shipment = _build(status: ShipmentStatus.shipped);
      expect(shipment.totalDeliveredQuantity, 0);
    });
  });

  group('Shipment.isFullyDelivered', () {
    test('is true only when status is delivered and there is quantity', () {
      final shipment = _build(
        status: ShipmentStatus.delivered,
        deliveredQuantities: const <String, int>{'item-1': 10, 'item-2': 5},
      );
      expect(shipment.isFullyDelivered, isTrue);
    });

    test('is false for partially_delivered even with some quantity moved', () {
      final shipment = _build(
        status: ShipmentStatus.partiallyDelivered,
        deliveredQuantities: const <String, int>{'item-1': 10},
      );
      expect(shipment.isFullyDelivered, isFalse);
    });

    test('is false for every open status', () {
      for (final status in ShipmentStatus.values) {
        if (status == ShipmentStatus.delivered) continue;
        expect(
          _build(status: status).isFullyDelivered,
          isFalse,
          reason: '$status must never be considered fully delivered',
        );
      }
    });
  });
}
