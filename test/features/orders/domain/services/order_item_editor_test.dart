import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderItemEditor', () {
    group('withAddedItems', () {
      test('appends a brand-new variant as-is', () {
        final result = OrderItemEditor.withAddedItems(
          const <OrderItem>[],
          <OrderItem>[_item(id: 'item-1', variantId: 'variant-1', quantity: 2)],
        );

        expect(result, hasLength(1));
        expect(result.single.variantId, 'variant-1');
        expect(result.single.quantity, 2);
        expect(result.single.subtotal, 20);
      });

      test('merges quantities for a variant already on the order and refreshes '
          'its unit price to the fresh addition', () {
        final existing = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 2,
            unitPrice: 10,
          ),
        ];

        final result = OrderItemEditor.withAddedItems(existing, <OrderItem>[
          _item(
            id: 'item-2',
            variantId: 'variant-1',
            quantity: 3,
            unitPrice: 12,
          ),
        ]);

        expect(result, hasLength(1));
        expect(result.single.id, 'item-1');
        expect(result.single.quantity, 5);
        expect(result.single.unitPrice, 12);
        expect(result.single.subtotal, 60);
      });

      test('keeps every other item untouched when merging one variant', () {
        final existing = <OrderItem>[
          _item(id: 'item-1', variantId: 'variant-1', quantity: 1),
          _item(id: 'item-2', variantId: 'variant-2', quantity: 4),
        ];

        final result = OrderItemEditor.withAddedItems(existing, <OrderItem>[
          _item(id: 'item-3', variantId: 'variant-1', quantity: 1),
        ]);

        expect(result, hasLength(2));
        expect(
          result.firstWhere((item) => item.variantId == 'variant-1').quantity,
          2,
        );
        expect(
          result.firstWhere((item) => item.variantId == 'variant-2').quantity,
          4,
        );
      });

      test(
        'never merges a bare catalog addition into an existing pack item for '
        'the same variant (TASK-208)',
        () {
          final existing = <OrderItem>[
            _item(
              id: 'item-1',
              variantId: 'variant-1',
              quantity: 2,
            ).copyWith(packGroupId: 'group-1', packId: 'pack-1'),
          ];

          final result = OrderItemEditor.withAddedItems(existing, <OrderItem>[
            _item(id: 'item-2', variantId: 'variant-1', quantity: 1),
          ]);

          expect(result, hasLength(2));
          expect(result.firstWhere((item) => item.id == 'item-1').quantity, 2);
          expect(result.firstWhere((item) => item.id == 'item-2').quantity, 1);
        },
      );

      test('never merges two separate instances of the same pack for the same '
          'variant (TASK-208) — each packGroupId stays its own line', () {
        final existing = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 2,
          ).copyWith(packGroupId: 'group-1', packId: 'pack-1'),
        ];

        final result = OrderItemEditor.withAddedItems(existing, <OrderItem>[
          _item(
            id: 'item-2',
            variantId: 'variant-1',
            quantity: 2,
          ).copyWith(packGroupId: 'group-2', packId: 'pack-1'),
        ]);

        expect(result, hasLength(2));
        expect(result.map((item) => item.packGroupId), <String>[
          'group-1',
          'group-2',
        ]);
      });

      test('merges two additions sharing the same packGroupId and variant '
          '(retrying the exact same pack addition)', () {
        final existing = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 2,
          ).copyWith(packGroupId: 'group-1', packId: 'pack-1'),
        ];

        final result = OrderItemEditor.withAddedItems(existing, <OrderItem>[
          _item(
            id: 'item-2',
            variantId: 'variant-1',
            quantity: 2,
          ).copyWith(packGroupId: 'group-1', packId: 'pack-1'),
        ]);

        expect(result, hasLength(1));
        expect(result.single.quantity, 4);
      });
    });

    group('withRemovedPackGroup', () {
      test('removes every item sharing the packGroupId, keeps the rest', () {
        final items = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 1,
          ).copyWith(packGroupId: 'group-1'),
          _item(
            id: 'item-2',
            variantId: 'variant-2',
            quantity: 1,
          ).copyWith(packGroupId: 'group-1'),
          _item(id: 'item-3', variantId: 'variant-3', quantity: 1),
        ];

        final result = OrderItemEditor.withRemovedPackGroup(
          items,
          packGroupId: 'group-1',
        );

        expect(result, hasLength(1));
        expect(result.single.id, 'item-3');
      });

      test('is a no-op when the packGroupId is not found', () {
        final items = <OrderItem>[
          _item(id: 'item-1', variantId: 'variant-1', quantity: 1),
        ];

        final result = OrderItemEditor.withRemovedPackGroup(
          items,
          packGroupId: 'missing',
        );

        expect(result, hasLength(1));
      });
    });

    group('withUpdatedQuantity', () {
      test('recomputes the subtotal for the matching item', () {
        final items = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 2,
            unitPrice: 15,
          ),
        ];

        final result = OrderItemEditor.withUpdatedQuantity(
          items,
          itemId: 'item-1',
          quantity: 4,
        );

        expect(result.single.quantity, 4);
        expect(result.single.subtotal, 60);
      });

      test('removes the item when the new quantity is zero or less', () {
        final items = <OrderItem>[
          _item(id: 'item-1', variantId: 'variant-1', quantity: 2),
        ];

        final result = OrderItemEditor.withUpdatedQuantity(
          items,
          itemId: 'item-1',
          quantity: 0,
        );

        expect(result, isEmpty);
      });

      test('never lets a discount push the subtotal negative', () {
        final items = <OrderItem>[
          _item(
            id: 'item-1',
            variantId: 'variant-1',
            quantity: 1,
            unitPrice: 10,
          ).copyWith(discountAmount: 999),
        ];

        final result = OrderItemEditor.withUpdatedQuantity(
          items,
          itemId: 'item-1',
          quantity: 1,
        );

        expect(result.single.subtotal, 0);
      });
    });

    group('withRemovedItem', () {
      test('removes only the targeted item', () {
        final items = <OrderItem>[
          _item(id: 'item-1', variantId: 'variant-1', quantity: 1),
          _item(id: 'item-2', variantId: 'variant-2', quantity: 1),
        ];

        final result = OrderItemEditor.withRemovedItem(items, itemId: 'item-1');

        expect(result, hasLength(1));
        expect(result.single.id, 'item-2');
      });

      test('is a no-op when the item id is not found', () {
        final items = <OrderItem>[
          _item(id: 'item-1', variantId: 'variant-1', quantity: 1),
        ];

        final result = OrderItemEditor.withRemovedItem(
          items,
          itemId: 'missing',
        );

        expect(result, hasLength(1));
      });
    });
  });
}

OrderItem _item({
  required String id,
  required String variantId,
  required int quantity,
  double unitPrice = 10,
}) {
  return OrderItem(
    id: id,
    variantId: variantId,
    productId: 'product-1',
    quantity: quantity,
    unitPrice: unitPrice,
    subtotal: quantity * unitPrice,
  );
}
