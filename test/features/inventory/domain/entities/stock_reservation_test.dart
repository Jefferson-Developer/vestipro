import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/inventory/inventory.dart';

void main() {
  group('StockReservation', () {
    test('isActive is true only for active reservations', () {
      final active = StockReservation(
        id: 'reservation-1',
        organizationId: 'org-1',
        variantId: 'variant-1',
        warehouseId: 'wh-1',
        orderDraftId: 'draft-1',
        quantity: 3,
        reservedBy: 'rep-1',
        reservedAt: DateTime.utc(2026, 8, 28, 12),
        expiresAt: DateTime.utc(2026, 8, 28, 12, 15),
        status: StockReservationStatus.active,
      );
      final released = StockReservation(
        id: 'reservation-2',
        organizationId: 'org-1',
        variantId: 'variant-1',
        warehouseId: 'wh-1',
        orderDraftId: 'draft-1',
        quantity: 3,
        reservedBy: 'rep-1',
        reservedAt: DateTime.utc(2026, 8, 28, 12),
        expiresAt: DateTime.utc(2026, 8, 28, 12, 15),
        status: StockReservationStatus.released,
        releasedAt: DateTime.utc(2026, 8, 28, 12, 5),
        releasedBy: 'rep-1',
      );

      expect(active.isActive, isTrue);
      expect(released.isActive, isFalse);
    });
  });
}
