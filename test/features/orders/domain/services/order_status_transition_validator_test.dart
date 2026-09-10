import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/orders/orders.dart';

void main() {
  group('OrderStatusTransitionValidator', () {
    const validator = OrderStatusTransitionValidator();

    // The exact matrix TASK-095 specifies (`tasks.md` seção 9.1): every pair
    // not listed here must be rejected — asserted by the exhaustive test
    // below, which walks every possible (from, to) combination.
    const expectedValidTransitions = <OrderStatus, Set<OrderStatus>>{
      OrderStatus.draft: {OrderStatus.pendingSync, OrderStatus.cancelled},
      OrderStatus.pendingSync: {OrderStatus.submitted, OrderStatus.cancelled},
      OrderStatus.submitted: {OrderStatus.underReview, OrderStatus.cancelled},
      OrderStatus.underReview: {
        OrderStatus.approved,
        OrderStatus.rejected,
        OrderStatus.cancelled,
      },
      OrderStatus.approved: {OrderStatus.processing, OrderStatus.cancelled},
      OrderStatus.rejected: {OrderStatus.cancelled},
      OrderStatus.processing: {
        OrderStatus.invoiced,
        OrderStatus.partiallyInvoiced,
        OrderStatus.cancelled,
      },
      OrderStatus.invoiced: {
        OrderStatus.shipped,
        OrderStatus.cancelled,
        OrderStatus.partiallyReturned,
        OrderStatus.returned,
      },
      OrderStatus.partiallyInvoiced: {
        OrderStatus.invoiced,
        OrderStatus.shipped,
        OrderStatus.cancelled,
        OrderStatus.partiallyReturned,
        OrderStatus.returned,
      },
      OrderStatus.shipped: {
        OrderStatus.delivered,
        OrderStatus.partiallyReturned,
        OrderStatus.returned,
      },
      OrderStatus.delivered: {
        OrderStatus.partiallyReturned,
        OrderStatus.returned,
      },
      OrderStatus.cancelled: {},
      OrderStatus.partiallyReturned: {OrderStatus.returned},
      OrderStatus.returned: {},
    };

    test('covers every OrderStatus as a "from" key', () {
      expect(expectedValidTransitions.keys.toSet(), OrderStatus.values.toSet());
    });

    test(
      'canTransition matches the expected matrix for every (from, to) pair',
      () {
        for (final from in OrderStatus.values) {
          for (final to in OrderStatus.values) {
            final expected = expectedValidTransitions[from]!.contains(to);
            expect(
              validator.canTransition(from, to),
              expected,
              reason:
                  'canTransition(${from.name}, ${to.name}) should be '
                  '$expected',
            );
          }
        }
      },
    );

    test('a status never transitions to itself', () {
      for (final status in OrderStatus.values) {
        expect(validator.canTransition(status, status), isFalse);
      }
    });

    test('does not allow skipping straight from draft to delivered', () {
      expect(
        validator.canTransition(OrderStatus.draft, OrderStatus.delivered),
        isFalse,
      );
    });

    test('cancelled and returned are terminal', () {
      for (final to in OrderStatus.values) {
        expect(validator.canTransition(OrderStatus.cancelled, to), isFalse);
        expect(validator.canTransition(OrderStatus.returned, to), isFalse);
      }
    });

    test('shipped can no longer be cancelled', () {
      expect(
        validator.canTransition(OrderStatus.shipped, OrderStatus.cancelled),
        isFalse,
      );
    });

    test('invoiced/partiallyInvoiced/shipped/delivered can transition into '
        'partiallyReturned/returned (EPIC-30, TASK-199 — devoluções), never '
        'straight back into an earlier commercial status', () {
      for (final from in <OrderStatus>[
        OrderStatus.invoiced,
        OrderStatus.partiallyInvoiced,
        OrderStatus.shipped,
        OrderStatus.delivered,
      ]) {
        expect(
          validator.canTransition(from, OrderStatus.partiallyReturned),
          isTrue,
          reason: '${from.name} -> partiallyReturned should be allowed.',
        );
        expect(
          validator.canTransition(from, OrderStatus.returned),
          isTrue,
          reason: '${from.name} -> returned should be allowed.',
        );
      }
    });

    test('partiallyReturned only ever transitions into returned, never back '
        'into an earlier commercial status', () {
      expect(
        validator.canTransition(
          OrderStatus.partiallyReturned,
          OrderStatus.returned,
        ),
        isTrue,
      );
      for (final to in OrderStatus.values) {
        if (to == OrderStatus.returned) continue;
        expect(
          validator.canTransition(OrderStatus.partiallyReturned, to),
          isFalse,
          reason: 'partiallyReturned -> ${to.name} should be rejected.',
        );
      }
    });

    test('validateTransition returns normally for a valid transition', () {
      expect(
        () => validator.validateTransition(
          from: OrderStatus.draft,
          to: OrderStatus.pendingSync,
        ),
        returnsNormally,
      );
    });

    test('validateTransition throws ValidationException for an invalid '
        'transition', () {
      expect(
        () => validator.validateTransition(
          from: OrderStatus.draft,
          to: OrderStatus.delivered,
        ),
        throwsA(
          isA<ValidationException>().having(
            (exception) => exception.code,
            'code',
            'invalid_order_status_transition',
          ),
        ),
      );
    });
  });
}
