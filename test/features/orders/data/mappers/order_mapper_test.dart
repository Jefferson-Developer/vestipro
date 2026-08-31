import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderMapper', () {
    const mapper = OrderMapper();
    final now = DateTime.utc(2026, 1, 1);

    OrderAddress address({String city = 'Blumenau'}) {
      return OrderAddress(
        street: 'Rua das Flores',
        number: '123',
        complement: 'Sala 4',
        district: 'Centro',
        city: city,
        state: 'SC',
        zipCode: '89010000',
      );
    }

    OrderItem item() {
      return const OrderItem(
        id: 'item-1',
        variantId: 'variant-1',
        productId: 'product-1',
        quantity: 3,
        unitPrice: 99.9,
        discountAmount: 10,
        surchargeAmount: 0,
        subtotal: 289.7,
      );
    }

    OrderStatusHistoryEntry historyEntry() {
      return OrderStatusHistoryEntry(
        previousStatus: OrderStatus.draft,
        newStatus: OrderStatus.pendingSync,
        changedAt: now,
        actorId: 'user-1',
        reason: 'Sincronizado automaticamente',
      );
    }

    /// Every field required/optional per `tasks.md` seção 9, all populated,
    /// so the round-trip test below actually exercises every field.
    Order fullOrder() {
      return Order(
        id: 'order-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
        customerId: 'customer-1',
        sellerId: 'seller-1',
        orderNumber: '000123',
        deliveryAddress: address(city: 'Blumenau'),
        billingAddress: address(city: 'Gaspar'),
        priceListId: 'price-list-1',
        paymentTermId: 'payment-term-1',
        carrierId: 'carrier-1',
        collectionId: 'collection-1',
        orderType: 'normal',
        items: [item()],
        discountAmount: 15,
        surchargeAmount: 5,
        shippingAmount: 20,
        taxAmount: 12.5,
        notes: 'Entregar pela manhã',
        attachmentUrls: const ['https://files.example.com/a.pdf'],
        status: OrderStatus.pendingSync,
        statusHistory: [historyEntry()],
        approvedBy: 'approver-1',
        approvedAt: now,
        rejectionReason: null,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        deletedAt: null,
        version: 2,
        syncStatus: OrderSyncStatus.synced,
      );
    }

    /// Every optional field left null/empty, to exercise that side of the
    /// mapper too.
    Order minimalOrder() {
      return Order(
        id: 'order-2',
        organizationId: 'org-1',
        companyId: 'company-1',
        branchId: 'branch-1',
        customerId: 'customer-1',
        sellerId: 'seller-1',
        deliveryAddress: address(),
        billingAddress: address(),
        priceListId: 'price-list-1',
        paymentTermId: 'payment-term-1',
        status: OrderStatus.draft,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: OrderSyncStatus.pending,
      );
    }

    test(
      'toDto/toEntity round-trip preserves every field (fully populated)',
      () {
        final original = fullOrder();

        final roundTripped = mapper.toEntity(mapper.toDto(original));

        expect(roundTripped, original);
      },
    );

    test(
      'toDto/toEntity round-trip preserves every field (minimal/optional-null)',
      () {
        final original = minimalOrder();

        final roundTripped = mapper.toEntity(mapper.toDto(original));

        expect(roundTripped, original);
      },
    );

    test('statusToDto/statusToEntity round-trip for every OrderStatus', () {
      for (final status in OrderStatus.values) {
        expect(mapper.statusToEntity(mapper.statusToDto(status)), status);
      }
    });

    test('syncStatusToDto/syncStatusToEntity round-trip for every '
        'OrderSyncStatus', () {
      for (final syncStatus in OrderSyncStatus.values) {
        expect(
          mapper.syncStatusToEntity(mapper.syncStatusToDto(syncStatus)),
          syncStatus,
        );
      }
    });

    test('statusToEntity rejects an unknown status code', () {
      expect(
        () => mapper.statusToEntity('not_a_real_status'),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.code,
            'code',
            'invalid_order_status',
          ),
        ),
      );
    });

    test('syncStatusToEntity rejects an unknown syncStatus code', () {
      expect(
        () => mapper.syncStatusToEntity('not_a_real_sync_status'),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.code,
            'code',
            'invalid_order_sync_status',
          ),
        ),
      );
    });

    test(
      'itemToDto/itemToEntity round-trip preserves every OrderItem field',
      () {
        final original = item();

        final roundTripped = mapper.itemToEntity(mapper.itemToDto(original));

        expect(roundTripped, original);
      },
    );

    test('historyEntryToDto/historyEntryToEntity round-trip preserves every '
        'field, including a null previousStatus', () {
      final withPrevious = historyEntry();
      expect(
        mapper.historyEntryToEntity(mapper.historyEntryToDto(withPrevious)),
        withPrevious,
      );

      final withoutPrevious = OrderStatusHistoryEntry(
        newStatus: OrderStatus.draft,
        changedAt: now,
        actorId: 'user-1',
      );
      expect(
        mapper.historyEntryToEntity(mapper.historyEntryToDto(withoutPrevious)),
        withoutPrevious,
      );
    });
  });
}
